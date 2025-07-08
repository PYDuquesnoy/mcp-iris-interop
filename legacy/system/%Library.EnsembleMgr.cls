/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syConfig, %syNLS, %occErrors, %syInterop, %products)

Class %Library.EnsembleMgr [ System = 4 ]
{

/// Portal homepage for this version
Parameter PORTALHOMEPAGE As STRING = "%25CSP.Portal.Home.zen";

/// Default CSP authentication methods
Parameter DEFAULTCSPAUTHMETHODS As INTEGER = 32;

/// Default database resource name
Parameter DEFAULTDBRESOURCE As STRING = "%DB_%DEFAULT";

/// Remove ENSLIB namespace if it already exists AND doesn't reference
/// any data or routines mapped from other databases.
Parameter REMOVEEENSLIBNAMESPACE As BOOLEAN = 1;

/// Create the ENSLIB namespace during upgrades/installs.
Parameter CREATEENSLIBNAMESPACE As BOOLEAN = 0;

/// Default ENSLIB
Parameter ENSLIB As STRING = "ENSLIB";

/// Default HSLIB
Parameter HSLIB As STRING = "HSLIB";

/// where the viewer will get installed
Parameter VIEWERLIB As STRING = "VIEWERLIB";

/// Suffix for temporary global database
Parameter TEMPSUFFIX As STRING = "ENSTEMP";

/// Suffix for secondary global database
Parameter SECONDARYSUFFIX As STRING = "SECONDARY";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Checks for Interoperability installation
ClassMethod IsEnsembleInstalled() As %Boolean [ CodeMode = expression ]
{
''$D(^%SYS("Ensemble","InstalledNamespace"))
}

/// Checks if DICOM is installed
ClassMethod IsDICOMInstalled() As %Boolean [ CodeMode = expression ]
{
..IsEnsembleInstalled()&&(''$Data(^|..GetENSLIB(1)|EnsDICOM.Dictionary))
}

/// Checks for HealthShare installation
ClassMethod IsHealthShareInstalled() As %Boolean [ Internal ]
{
	Set tInstalled=0
	try {
		Set tInstalled=##class(%ZHSLIB.HealthShareMgr).IsHealthShareInstalled()
	} Catch ex {
	}
	Quit tInstalled
}

/// Deprecated, retained for backward compatibility
ClassMethod IsFoundationInstalled() As %Boolean [ Deprecated, Internal ]
{
	Set tInstalled=0
	try {
		Set tInstalled=##class(%ZHSLIB.HealthShareMgr).IsFoundationInstalled()
	} Catch ex {
	}
	Quit tInstalled
}

/// Checks if current namespace is production-enabled
ClassMethod IsEnsembleNamespace(pNamespace = {$namespace}) As %Boolean
{
	#dim tIsEnsNS As %Boolean = 0
	Try {
		Set tIsEnsNS = $select(pNamespace = "%SYS": 0, 1: ''$Data(^|pNamespace|oddCOM("Ens.StudioManager")))
	}	
	Catch { 
		#; If the above check fails, the user doesn't have permission for the Ensemble ^oddCOM nodes
	}
	Quit tIsEnsNS
}

/// Checks if current namespace is HealthShare-enabled
ClassMethod IsHealthShareNamespace(pNamespace = {$namespace}) As %Boolean
{
	Set tIsNS=0
	try {
		Set tIsNS=##class(%ZHSLIB.HealthShareMgr).IsHealthShareNamespace(pNamespace)
	} Catch ex {
	}
	Quit tIsNS
}

/// Get the directory or implicit namespace for the ENSLIB database.
/// <var>pImplicit</var> indicates whether the full implicit namespace should be returned,
/// and <var>pNormalized</var> indicates whether the directory should be normalized.
ClassMethod GetENSLIB(pImplicit As %Boolean = 0, pNormalized As %Boolean = 1) As %String [ CodeMode = expression ]
{
$select(pImplicit: "^^", 1: "")_##class(%Library.File).SubDirectoryName(##class(%Library.File).SubDirectoryName($system.Util.InstallDirectory(), "mgr", pNormalized),"enslib",pNormalized)
}

/// Returns the "path" portion of the Interoperability management URL for a given namespace. If the namespace
/// is *not* production-enabled, then it will return empty string.
/// If <var>pAppendHomePage</var> is false, it will only return the CSP application path.
/// This does not prepend a non empty optional URLPrefix.
ClassMethod DetermineMgmtURLForNamespace(pNamespace As %String = {$namespace}, pAppendHomePage As %Boolean = 1) As %String
{
	#dim tUrl As %String
	#dim tDefaultUrl As %String
	Set pNamespace = $ZCVT(pNamespace,"U")
	#; Use EnsPortal.EventLog because %CSP.Portal.Home is always mapped to /csp/sys/
	Set tDefaultUrl = $system.CSP.GetPortalApp(pNamespace,"EnsPortal.EventLog.zen")
	If tDefaultUrl = "" Quit ""
	#; Allow overriding Mgmt URL if not HealthShare nor HealthConnect
	If ($$$ISCPRODUCTCODE'=$$$HealthShareProductKey)&&$DATA(^%SYS("Ensemble","InstalledNamespace",pNamespace)) {
		// Grab the URL from the global (if present)
		Set tUrl = ^%SYS("Ensemble","InstalledNamespace",pNamespace)

		// Ensure it isn't just a suffix (or "")
		If tUrl = "" {
			Set tUrl = tDefaultUrl
		}
		ElseIf $extract(tUrl,1) '= "/" {
			Set tUrl = tDefaultUrl _ $select($extract(tDefaultUrl,*) = "/": "", 1: "/") _ tUrl
		}

		// And add the page part
		If $P(tUrl,"/",$L(tUrl,"/"))'["." {
			Set:$E(tUrl,$L(tUrl))'="/" tUrl = tUrl_"/"
			If pAppendHomePage {
				Set tUrl = tUrl _ ..#PORTALHOMEPAGE
			}
		}
	} ElseIf ..IsHealthShareNamespace(pNamespace) {
		#; ..IsHealthShareNamespace() covers HealthShare, HealthConnect & IRIS for Health 
		Set tUrl="/csp/healthshare/"_$TR($ZCVT(pNamespace,"L"),"%")_"/"_$S(pAppendHomePage=0:"",1:..#PORTALHOMEPAGE)
	} Else {
		// Use the default App/URL for this namespace
		Set tUrl = tDefaultUrl
		//If there's no end /, then if this gets called by DeleteNamespace, it can delete the wrong app,
		//since that removes the last / piece
		Set:$E(tUrl,$L(tUrl))'="/" tUrl = tUrl_"/"
	}

	Quit tUrl
}

ClassMethod OnSystemStartup(Output pConsoleLog As %String, pIsStartup As %Boolean = 0) As %Boolean
{
	New $namespace
	Try {
		/* 
			This method can be called twice at instance startup at Ensemble^STU - 
			once directly by ^STU at startup and once indirectly via ^MIRRORMGR 
			when becomes primary.
			The order can vary.
			Use fact that CACHETEMP database is initialized at system startup before Mirror daemons are started.
			This method can also be called once during mirror failover.
		*/
		Lock +$$$EnsStartupGlobal
		#Dim tLockedInitialize As %Boolean = 1

		#Dim tNamespaceProductionType = ..namespaceProductionType()

		Kill pConsoleLog
		Set pConsoleLog=0

		#dim tHSVersion = ""
		Try {Set:..IsHealthShareInstalled() tHSVersion=##class(%ZHSLIB.HealthShareMgr).VersionInfo(),pConsoleLog($increment(pConsoleLog))=$lb(0,tHSVersion)} Catch {}
		Try {Do ##class(%ZHSLIB.HealthShareMgr).OnStartHealthShare(pIsStartup)} Catch ex {}

		If pIsStartup {
			Set $$$EnsStartupGlobal=$Job
		} Else {
			/*
				We could be here during instance startup or during failover and becoming primary.
				In case the startup temp global has been deleted use uptime as a safeguard to ensure failover proceeds
			*/
			If '$Data($$$EnsStartupGlobal)#2 {
				#dim tFailoverTimeout As %Integer = $Get(^%SYS("Ensemble","OnSystemStartup","PrimaryLimit"),3600)
				If tFailoverTimeout'=+tFailoverTimeout Set tFailoverTimeout = 3600
				If $ZH<tFailoverTimeout {
					#;Deduce here during instance startup and OnSystemStartup() will be called again momentarily
					If ..IsEnsembleInstalled() Set pConsoleLog($increment(pConsoleLog))=$lb(0,"Initializing "_tNamespaceProductionType_" during mirror initialization deferred to system startup")
					Quit
				}
			}
		}

		If pIsStartup Kill ^%SYS("Ensemble","RunningNamespace")
		
		// Installation checking is now done via an explicit call from ^STU earlier in the install/upgrade process.
		
		If $DATA(^%SYS("Ensemble")) {
			If +$get(^CONFIG("Startup","EnsembleAutoStart")) {
				Set pConsoleLog($increment(pConsoleLog))=$lb(0,"Initializing "_tNamespaceProductionType_" during "_$select(pIsStartup: "system startup", 1: "mirror initialization"))
				If $System.License.GetFeature(1)=0 {
					Set pConsoleLog($increment(pConsoleLog))=$lb(0,"Not licensed for "_tNamespaceProductionType_", auto-start skipped.")
					Quit
				}
				
				Set tIsPrimary = 1
				Set tIsMirrorMember = $system.Mirror.IsMember()
				If (tIsMirrorMember) {
					Set tIsPrimary = $system.Mirror.IsPrimary()
					Set $namespace = "%SYS"
					Set tSC = ..findMirroredNamespaces(.tMirNamespaces)
					If $$$ISERR(tSC) {
						Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production AutoStart: Unable to determine which "_tNamespaceProductionType_" namespaces contain mirrored data due to error: "_$system.Status.GetErrorText(tSC)_"; NOT auto-starting productions")
						Quit
					}
					If 'pIsStartup {
						#;Find any Interoperability jobs that are already running on the system
						Set tSC = ..findEnsembleJobs(.tRunningNamespaces)
						If $$$ISERR(tSC) {
							Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production AutoStart: Unable to determine which "_tNamespaceProductionType_" namespaces contain running "_tNamespaceProductionType_" jobs due to error: "_$system.Status.GetErrorText(tSC)_"; NOT auto-starting productions")
							Quit
						}
						Set tMirNS = ""
						For {
							Set tMirNS = $order(tMirNamespaces(tMirNS))
							Quit:(tMirNS = "")
							If $data(tRunningNamespaces(tMirNS)) Continue
							Kill ^%SYS("Ensemble","RunningNamespace",tMirNS)
						}
					}
				}
				
				#; Get a list of namespaces in Startup Priority Order
				#dim tNamespacesByStartupPriority
				Set tSC=..GetNamespacesByStartupPriority(.tNamespacesByStartupPriority)
				If $$$ISERR(tSC) {
					Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production AutoStart: ERROR determining Namespace order: '"_$system.Status.GetErrorText(tSC)_"' ")
					Quit
				}

				#dim tI As %Integer

				For tI=1:1:tNamespacesByStartupPriority {

					Set tNameSpace=$List(tNamespacesByStartupPriority(tI))

					#; Ignore mirrored namespaces if we are not the primary
					If ('tIsPrimary) && $data(tMirNamespaces(tNameSpace)) {
						/*
							Clean up local non mirrored temporary data but only 
							if we are not primary and this is a mirrored namspace
						*/
						If pIsStartup {
							try {
								Set $namespace = tNameSpace
								Do ..deleteEnsTempData(.pConsoleLog)
							} catch {
								Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production TempDataDelete: ERROR in namespace '"_$Namespace_"': "_$ZE_" tNameSpace='"_$G(tNameSpace)_"' $ZU(56,2)='"_$ZU(56,2)_"'")
							}
						}
						Continue
					}
					#; Don't process non-mirrored namespaces if this node is becoming the primary
					If ('pIsStartup) && '$data(tMirNamespaces(tNameSpace)) {
						Continue
					}
					#; Don't attempt autostart if namespace contains running Interoperability jobs
					If ('pIsStartup) && $data(tRunningNamespaces(tNameSpace)) {
						Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production AutoStart: "_tNamespaceProductionType_" jobs are running in namespace '"_tNameSpace_"'; NOT attempting to auto-start production in this namespace")
						Continue
					}
					try {
						Set $namespace = tNameSpace
						Set tSC=##class(Ens.Director).SystemStart(.tOptionalReplacementMessage)
						If $$$ISERR(tSC) {
							Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production AutoStart: ERROR in namespace '"_$Namespace_"': '"_$system.Status.GetErrorText(tSC)_"' $ZU(56,2)='"_$ZU(56,2)_"'")
						} ElseIf $G(^Ens.AutoStart)'="" {
							If $Get(tOptionalReplacementMessage)'="" {
								Set pConsoleLog($increment(pConsoleLog))=$lb(0,tNamespaceProductionType_": Auto Start of '" _ ^Ens.AutoStart _ "' in namespace '"_tNameSpace_"' : " _ tOptionalReplacementMessage)
							} Else {
								Set pConsoleLog($increment(pConsoleLog))=$lb(0,tNamespaceProductionType_": Starting production '" _ ^Ens.AutoStart _ "' in namespace '"_tNameSpace_"'.")
							}
						}
					} catch {
						Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production AutoStart: ERROR in namespace '"_$Namespace_"': "_$ZE_" tNameSpace='"_$G(tNameSpace)_"' $ZU(56,2)='"_$ZU(56,2)_"'")
					}
				}
			} Else {
				Set pConsoleLog($increment(pConsoleLog))=$lb(0,"Production auto-start is disabled.")
			}
		}
	}
	Catch ex {
		Set pConsoleLog($increment(pConsoleLog))=$lb(1,"Production AutoStart: ERROR in namespace '"_$Namespace_"': "_$ZE_" tNameSpace='"_$G(tNameSpace)_"' $ZU(56,2)='"_$ZU(56,2)_"'")
	}
	
	If $G(tLockedInitialize,0) Lock -$$$EnsStartupGlobal

	Quit 1
}

ClassMethod OnSystemShutdown(Output pConsoleLog As %String, Output pCancelShutdown As %Boolean) As %Boolean
{
	Set $ZT="Trap"
	do {
		Kill pConsoleLog
		Set pConsoleLog=0
		Set pCancelShutdown=0

		#Dim tMirNamespaces
		If $system.Mirror.IsMember() && '$system.Mirror.IsPrimary() {
			Do ..findMirroredNamespaces(.tMirNamespaces)
		}

		; Iterate through Running Productions building list by shutdown group.
		#Dim tNameSpacesToStopByGroup
		#Dim tShutdownGroup
		#Dim tNameSpace=$o(^%SYS("Ensemble","RunningNamespace",""))
		While tNameSpace '= "" {
			If '$Data(tMirNamespaces(tNameSpace)) {
				//We do not want to process this namespace if data is mirrored and this is not the primary instance
				Set tShutdownGroup = +$G(^%SYS("Ensemble","RunningNamespace",tNameSpace,"SystemShutdownGroup"),2)
				Set tNameSpacesToStopByGroup(tShutdownGroup,tNameSpace) = ""
			}
			Set tNameSpace=$o(^%SYS("Ensemble","RunningNamespace",tNameSpace))
		}

		Set tShutdownGroup = $Order(tNameSpacesToStopByGroup(""))
		While tShutdownGroup '= "" {

			Do ..stopProductionsByGroup(.tNameSpacesToStopByGroup, tShutdownGroup, .pConsoleLog, .pCancelShutdown)

			Set tShutdownGroup = $Order(tNameSpacesToStopByGroup(tShutdownGroup))

		}


	} while (0)
Exit
	Quit
Trap
	Set $ZT="",pConsoleLog($increment(pConsoleLog))=$lb(1,$ZE),pCancelShutdown=0
	Goto Exit
}

/// Internal method to make parallel production stop requests for a given group.
ClassMethod stopProductionsByGroup(ByRef pNameSpacesToStopByGroup, pShutdownGroup As %Integer = 0, ByRef pConsoleLog, Output pCancelShutdown As %Boolean) [ Internal ]
{
		; spawn background job to stop productions
		#Dim tEnsembleRunning=0
		#Dim tEnsembleTimedOut=0
		Try {

			Kill ^%SYS("Ensemble","StoppingProduction")
			New $NAMESPACE
			#Dim tNameSpace = ""

			// Only write out group number to log if not only group 2
			#Dim tGroupLogText = ""
			If ($Order(pNameSpacesToStopByGroup(2))'="") || ($Order(pNameSpacesToStopByGroup(2),-1)'="") {
				Set tGroupLogText = " (Shutdown Group "_pShutdownGroup_")"
			}

			#dim tTechnologyType = ..technologyType()

			For {
				Set tNameSpace=$O(pNameSpacesToStopByGroup(pShutdownGroup,tNameSpace))
				Quit:tNameSpace=""
				Try {
					Set $NAMESPACE = tNameSpace
					Set ^%SYS("Ensemble","StoppingProduction",tNameSpace,"timeout")=$zh+(##class(Ens.Director).GetRunningProductionShutdownTimeout()*2)+5
					Job ##class(Ens.Director).SystemStop()
					Set pConsoleLog($increment(pConsoleLog))=$lb(0,"Stopping "_tTechnologyType_" production in namespace '"_tNameSpace_" initiated at "_$ZTIME($PIECE($HOROLOG,",",2),1)_tGroupLogText)
					Set tEnsembleRunning=1
				}
				Catch {
					Set pConsoleLog($increment(pConsoleLog))=$lb(1,"ERROR stopping production in namespace "_tNameSpace_": "_$ZE_tGroupLogText)
				}
			}
			; wait for background jobs to kill ^%SYS("Ensemble","StoppingProduction",tNameSpace)
			For  {
				If $d(^%SYS("Ensemble","StoppingProduction"))=0 Quit
				Set tNameSpace="" For  {
					Set tNameSpace=$o(^%SYS("Ensemble","StoppingProduction",tNameSpace)) Quit:tNameSpace=""
					If $zh>$g(^%SYS("Ensemble","StoppingProduction",tNameSpace,"timeout")) {
						Kill ^%SYS("Ensemble","StoppingProduction",tNameSpace)
						Set tEnsembleTimedOut=1
						Set pConsoleLog($increment(pConsoleLog))=$lb(0,"Stop "_tTechnologyType_" production in namespace '"_tNameSpace_" timed out at "_$ZTIME($PIECE($HOROLOG,",",2),1)_tGroupLogText)
					}
				}
				Hang 1
			}
			If tEnsembleRunning {
				If 'tEnsembleTimedOut {
					Set pConsoleLog($increment(pConsoleLog))=$lb(0,"All "_tTechnologyType_" productions stopped."_tGroupLogText)
				} Else {
					Set pConsoleLog($increment(pConsoleLog))=$lb(0,"Not all "_tTechnologyType_" productions might be stopped due to time out."_tGroupLogText)
				}
			}
		} Catch {

			Set pConsoleLog($increment(pConsoleLog))=$lb(1,$ZE_tGroupLogText)
			Set pCancelShutdown=0

		}
}

/// Helper method which provides a quick heuristic to determine whether any Interoperability jobs
/// are running on a system. If more than two jobs are running in a namespace under the _Ensemble
/// user, then the namespace is considered to contain running Interoperability jobs.
ClassMethod findEnsembleJobs(Output pNamespaces As %String) As %Status [ Internal, Private ]
{
	Try {
		Set tSC = $$$OK
		Kill pNamespaces
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare("SELECT Namespace, COUNT(*) As Jobs FROM %SYS.ProcessQuery WHERE UserName = '_Ensemble' AND UserName IS NOT NULL GROUP BY Namespace")
		If $$$ISERR(tSC) Quit
		#dim tRS As %SQL.StatementResult
		Set tRS = tStatement.%Execute()
		While tRS.%Next(.tSC) && $$$ISOK(tSC) {
			If (tRS.Jobs > 2) && (tRS.Namespace '= "") Set pNamespaces(tRS.Namespace) = ""
		}
		If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Called by ^STU during an installation, update or when becoming primary (which can happen during installation/update or failover).
ClassMethod CheckForInstall() [ Internal ]
{
	#define REPORTCFI(%l,%x) Write !,?%l,%x
	#; Used as Array as well if has namespaces with mirrored DBs
	#dim tIsPrimary As %String = ($system.Mirror.IsMember() = 0)||($system.Mirror.IsPrimary())
	
	Set $ZT="Trap"
	/*
		This could be called from:
			1) First restart following installation during Manifest^STU
			2) From BecomePrimary^MIRRORMGR via Ensemble^STU. BecomePrimary can be called during installation or during failover.
			3) From normal STU procedure via D Ensemble^STU
	*/
	Set $Test = 0,tWaited=-10
	While '$Test {
		Set tWaited = tWaited+10
		If tWaited Do ##class(%SYS.System).WriteToConsoleLog("CheckForInstall waiting on lock to proceed")
		Lock +^%SYS("Ensemble","RunOnce","InitializeEnsemble"):10
	}
	Set tLockedInitialize=1
	#dim tNamespaceProductionType = ..namespaceProductionType()
	do {
		// Check for install/upgrade
		If $DATA(^%SYS("Ensemble","RunOnce","InitializeEnsemble")) {
			Set tProduct = $GET(^%SYS("Ensemble","RunOnce","InitializeEnsemble"))
			Do ##class(%SYS.System).WriteToConsoleLog(tNamespaceProductionType_": Installing "_tProduct)
			
			// Open a log file
			Set tIO = $IO
			Set tFilenameRoot = "ensinstall"
			Set tFileExtension = ".log"
			Set tCounter = 0
			Set tManagerDir = $system.Util.ManagerDirectory()
			Set tExists = 1
			While tExists {
				Set tCurrFilename = tFilenameRoot _ $select(tCounter > 0: "_"_tCounter, 1: "") _ tFileExtension
				Set tLog = ##class(%File).NormalizeFilename(tCurrFilename,tManagerDir)
				Set tExists = ##class(%Library.File).Exists(tLog)
				Set tCounter = tCounter + 1
			}
			Open tLog:"WNS"
			Use tLog

			// During install, make sure we're in UTF-8 mode so that localized messages don't get corrupted
			$$$SETIO("UTF8")

			$$$REPORTCFI(0,"")
			$$$REPORTCFI(0,"*************************************************************************************")
			$$$REPORTCFI(0,"Installation/upgrade of "_tProduct_" started at "_$zdatetime($zdatetimeh($ztimestamp,-3),3,,3))
			$$$REPORTCFI(0,"*************************************************************************************")
			$$$REPORTCFI(0,"")

	 		// Check whether Ensemble AutoStart is enabled at a system level if we are upgrading from Cache
	 		If '..IsEnsembleInstalled() {
		 		Try {
			 		$$$REPORTCFI(0,"Checking Production AutoStart setting in CPF file.")
			 		Set tToggleCPFAutoStart = 0
			 		Kill tPrevProps
			 		Set tSC = ##class(Config.Startup).Get(.tPrevProps)
			 		If $$$ISERR(tSC) {
				 		$$$REPORTCFI(1,"Error getting properties from Config.Startup: "_$system.Status.GetErrorText(tSC))
			 		}
			 		Else {
				 		Set tToggleCPFAutoStart = (0 = $get(tPrevProps("EnsembleAutoStart"),-1))
			 		}
			 		
			 		If tToggleCPFAutoStart {
				 		$$$REPORTCFI(1,"Enabling Production AutoStart setting in CPF file.")
				 		Kill tProps
				 		Set tProps("EnsembleAutoStart") = 1
				 		Set tSC = ##class(Config.Startup).Modify(.tProps)
				 		If $$$ISERR(tSC) {
				 			$$$REPORTCFI(1,"Error updating Config.Startup: "_$system.Status.GetErrorText(tSC))
			 			}
			 		}
		 		}
		 		Catch ex {
			 		$$$REPORTCFI(1,"Error checking Production AutoStart setting in CPF: "_$system.Status.GetErrorText(ex.AsStatus()))
			 	}
	 		}

	 		Set tSC = $$$OK
	 		If 'tIsPrimary {
		 		Set tSC = ..findMirroredNamespaces(.tMirNamespaces)
		 		If $$$ISOK(tSC) {
			 		Merge tIsPrimary("MirrorNS") = tMirNamespaces
		 		}
	 		}

			// Now let's install
			If $$$ISOK(tSC) {
				Set tSC = ..InitializeEnsemble(1, .tIsPrimary)
			}
		
			If $$$ISOK(tSC) {
				// Check for HealthShare initialization
				If (",irishealth,healthshare,healthconnect,"[(","_$ZCVT(tProduct,"L")_",")) {
					Set tSC = ..InitializeHealthShare(1,, .tIsPrimary)
				}
			}
			
			If $$$ISERR(tSC) {
				// Report this error so it appears in the log
				$$$REPORTCFI(0,"Installation failed: "_$system.Status.GetErrorText(tSC))
			}
			ElseIf 'tIsPrimary {
				Do ##class(%SYS.System).WriteToConsoleLog("Completed non-primary installation for "_tProduct_"; setting flag for primary upgrade steps")
				$$$REPORTCFI(0,"Installation completed for non-primary instance; setting flag to confirm primary upgrade steps are completed on the next primary startup")
				Set ^%SYS("Ensemble","Mirror","UpdateCheck") = 1
			}
		
			// Close the log file
			Use tIO
			Close tLog
			
			If $$$ISERR(tSC) {
				Do ##class(%SYS.System).WriteToConsoleLog(tNamespaceProductionType_": install failed, check log "_tLog_": "_$system.Status.GetErrorText(tSC),0,1)
			}
		}
		ElseIf tIsPrimary && $data(^%SYS("Ensemble","Mirror","UpdateCheck")) {
			Try {
				Set tIO = $IO
				Do ##class(%Device).Broadcast("", "Confirming completion of "_tNamespaceProductionType_" Mirror upgrade...")
				Set tStartNS = $namespace
				Set tCurrentVersion = ..getVersion()
				
				// Open a log file
				Set tLog = ##class(%File).NormalizeFilename($System.Util.ManagerDirectory()_"ensinstall.log")
				Set tFile = ##class(%IO.FileStream).%New()
				Do tFile.Open(tLog, "RWAES",,"UTF-8",.tSC)
				If $$$ISERR(tSC) Quit
				Use tLog
				$$$REPORTCFI(0,!)
				$$$REPORTCFI(0,"Confirming completion of "_tNamespaceProductionType_" Mirror upgrade...")
				
				$$$REPORTCFI(2,"+ Finding namespaces with mirrored data")
				Set tSC = ..findMirroredNamespaces(.tMirNamespaces)
				If $$$ISERR(tSC) Quit
				
				Set tNS = ""
				For {
					Set tNS = $order(tMirNamespaces(tNS))
					Quit:(tNS = "")
					Set $namespace = tNS
					$$$REPORTCFI(2,"+ Checking upgrade status for namespace "_tNS)
					Set tStoredVersion = $get(^Ens.Mirror("Version"))
					If '$ListSame(tStoredVersion, tCurrentVersion) {
						$$$REPORTCFI(2, "+ Completing "_tNamespaceProductionType_" Mirror upgrade for namespace "_tNS)
						Do ##class(%Device).Broadcast("", "Completing "_tNamespaceProductionType_" Mirror upgrade for namespace "_tNS)
						Set tSC = ..dataUpgradeSteps(tNS,1)
						If $$$ISERR(tSC) Quit
						$$$REPORTCFI(2, "+ Upgrade completed for namespace "_tNS)
					}
				}
				If $$$ISERR(tSC) Quit
				
				$$$REPORTCFI(0, tNamespaceProductionType_" Mirror upgrade confirmed as complete")
				Do ##class(%Device).Broadcast("", tNamespaceProductionType_" Mirror upgrade confirmed as complete")
				Kill ^%SYS("Ensemble","Mirror","UpdateCheck")
			}
			Catch ex {
				Set tSC = ex.AsStatus()
			}
			Use tIO
			Kill tFile
			Set $namespace = tStartNS
			If $$$ISERR(tSC) {
				Do ##class(%Device).Broadcast("", tNamespaceProductionType_": install failed, check log "_tLog_": "_$system.Status.GetErrorText(tSC),1)
			}
		}
	} while (0)
Exit
	// Clean this up so we don't do it again
	If $G(tCleanExit,1) Kill ^%SYS("Ensemble","RunOnce","InitializeEnsemble")
	If $G(tLockedInitialize,0) Lock -^%SYS("Ensemble","RunOnce","InitializeEnsemble")
	Quit $$$OK
Trap
	Set $ZT=""
	Do ##class(%SYS.System).WriteToConsoleLog($ZE,0,1)
	Set tCleanExit = 0
	Goto Exit
}

/// Deprecated method. Use dataUpgradeSteps() instead.
ClassMethod mirrorUpgradeSteps(pTargetNS As %String, pVerbose As %Boolean = 0, pCompileCSPPages As %Boolean = 0) As %Status [ CodeMode = call, Deprecated, Internal ]
{
..dataUpgradeSteps(pTargetNS,pVerbose,pCompileCSPPages)
}

/// Perform Interoperability upgrade steps that modify data and thus need to occur when the instance
/// has write access to the data. The separation is used for mirrors where the primary mirror
/// member needs to complete the upgrade for the mirror set.
ClassMethod dataUpgradeSteps(pTargetNS As %String, pVerbose As %Boolean = 0, pCompileCSPPages As %Boolean = 0) As %Status [ Internal ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Set tSC = $$$OK
	Try {

		#; Do not do legacy upgrade procedures if not marked as an interop production namespace
		If '$Data(^%SYS("Ensemble","InstalledNamespace",$ZCVT(pTargetNS,"U"))) {
			Set tMsg = "* Skipping legacy Interoperability dataUpgradeSteps since not an Interop production namespace"
			$$$REPORT(4,tMsg)
			Quit
		}
		#; Do not do legacy upgrade procedures if read only default global or routine db
		Do ##class(%SYS.Namespace).GetAllNSInfo(pTargetNS,.tNSInfo)
		If $Get(tNSInfo("GlobalDB","ReadOnly"))||$Get(tNSInfo("RoutineDB","ReadOnly")) {
			Set tMsg = "* Skipping legacy Interoperability dataUpgradeSteps since databases mounted ReadOnly: "
			If $Get(tNSInfo("GlobalDB","ReadOnly")) {
				Set tMsg = tMsg _ "Default Global DB"
				Set:$Get(tNSInfo("RoutineDB","ReadOnly")) tMsg = tMsg _ " and "
			}
			Set:$Get(tNSInfo("RoutineDB","ReadOnly")) tMsg = tMsg _ "Default Routine DB"
			$$$REPORT(4,tMsg)
			Quit
		}
		Kill tNSInfo

		New $namespace
		// Change namespace before all upgrade work to try and avoid multiple namespace switches
		Set $namespace = pTargetNS

		#dim tNamespaceProductionType = ..namespaceProductionType()
		
		$$$REPORT(4,"* Adding "_tNamespaceProductionType_" SearchTables")
 		Set tSC = ..deploySearchTables(pTargetNS, pVerbose)
 		Quit:$$$ISERR(tSC)

		#; Set initial default purge settings if not already set
		Set tCurrentDefaultTextDescription = $$$Text("""Include message bodies"" default is OFF because some Productions may use message objects that are part of a a larger environment and not transitory.")_
			  $C(10,10)_$$$Text("""Purge only completed sessions"" default is ON to preserve messages not yet completely processed.")
		Set tPriorDefaultTextDescription = $$$Text("""Include message bodies"" is OFF because some Productions may use message objects that are part of a a larger environment and not transitory.")_
			  $C(10,10)_$$$Text("""Purge only completed sessions"" is ON to preserve messages not yet completely processed.")
		If '$D(^Ens.Configuration("PurgeSettings")) {
			$$$REPORT(4,"- Setting initial default Purge Settings")
			Set ^Ens.Configuration("PurgeSettings","BodiesToo")=0
			Set ^Ens.Configuration("PurgeSettings","KeepIntegrity")=1
			Set ^Ens.Configuration("PurgeSettings","Desc") = tCurrentDefaultTextDescription
		} ElseIf $Get(^Ens.Configuration("PurgeSettings","Desc"))=tPriorDefaultTextDescription {
			#; don't overwrite if customer changed the description
			Set ^Ens.Configuration("PurgeSettings","Desc") = tCurrentDefaultTextDescription
		}

		#; Upgrade to version where Ens.BusinessProcess storage of %MasterPendingResponses changes
        #; 2023-6
		Try {
			$$$REPORT(4,"* Converting Business Process Pending Responses list storage")
			Do ##class(Ens.BP.Utils.Upgrade).UpgradePendingResponsesStorage(.bpUpgradeLog,0,0)
			If $Get(bpUpgradeLog)>0 {
				For log=1:1:bpUpgradeLog {
					Set label = $Order(bpUpgradeLog(log,""),1,logText)
					While label'="" {
						$$$REPORT(6,"- "_label_": "_logText)
						Set label = $Order(bpUpgradeLog(log,label),1,logText)
					}
				}
			} Else {
				$$$REPORT(6,"- No Business Process Pending Responses to upgrade")
			}
		} Catch ex {
			If ex.Name = "<METHOD DOES NOT EXIST>" {
				$$$REPORT(6,"- Business Process storage upgrade not applicable for this upgrade")
			} Else {
				$$$REPORT(6,"- Error attempting Business Process storage upgrade:"_ex.DisplayString())
			}
		}
		
		#; Upgrade to version where X12 Relational Conditions are stored in the consolidated schema instead of the validation schema
        #; 2024.2
		Try {
			$$$REPORT(4,"* Converting Storage of X12 Relational Conditions")
			Set tCategory = "", tCount = 0, tSCX12 = $$$OK
			For {
				Set tCategory = $O(^EnsEDI.Schema(tCategory),1,tCatInfo)	Quit:(""=tCategory)
				Continue:$Case(tCategory,"HIPAA_5010":1,"HIPAA_4010":1,"HIPAA_6020":1,:0)
				Continue:("X"'=$P(tCatInfo,"|"))
				Set tDocStruct = "", tUpdatedCat=0
				For {
					Set tDocStruct = $O(^EnsEDI.Schema(tCategory,tDocStruct))	Quit:(""=tDocStruct)
					Continue:'$D(^EnsEDI.Schema(tCategory,tDocStruct,"r"))
					Do $I(tCount)
					Set tSCX12 = ##class(EnsLib.EDI.SEF.Schema).mergeRulesToX12(tCategory,tDocStruct)
					If $$$ISERR(tSCX12) {
						$$$REPORT(6,"- Error attempting X12 relational condition storage upgrade:"_ex.DisplayString())
						Quit
					}
					Set tUpdatedCat = 1
				}
				Quit:$$$ISERR(tSCX12)
				If tUpdatedCat {
					$$$REPORT(6,"- Updated relational condition storage for X12 schema category '"_tCategory_"'")
				}
			}
			If 'tCount {
				$$$REPORT(6,"- No custom X12 schemas in need of upgrade")
			}
		} Catch ex {
			If ex.Name = "<METHOD DOES NOT EXIST>" {
				$$$REPORT(6,"- X12 relational condition storage upgrade not applicable for this upgrade")
			} Else {
				$$$REPORT(6,"- Error attempting X12 relational condition storage upgrade:"_ex.DisplayString())
			}
		}

		Set tCSPApp = ..DetermineMgmtURLForNamespace(pTargetNS,0)
		If pCompileCSPPages {
			Set tFlags = "c"_$select(pVerbose: "+", 1:"-")_"d"
			$$$REPORT(4,"* Compiling portal '"_tCSPApp_"' for namespace "_pTargetNS)
			Set tSC = $system.CSP.LoadPageDir(tCSPApp, tFlags)
			If $$$ISERR(tSC) Quit
		}
		Else {
			$$$REPORT(4,"* Legacy CSP Portal not installed, so no legacy CSP pages recompiled.")
		}

		$$$REPORT(4,"* Generating meta data for "_tNamespaceProductionType_" Analytics items")
		Set tSC = ..upgradeDashboards(pTargetNS,pVerbose,0)
		If $$$ISERR(tSC) && pVerbose Do $system.OBJ.DisplayError(tSC)

		Set ^Ens.Mirror("Version") = ..getVersion()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Builds array of interoperability namespaces that are mirrored.  Optionally will take pNamespaces argument (comma delimited) to check one or namespaces specifically (which ignores whether it is interoperability)
ClassMethod findMirroredNamespaces(Output pMirNamespaces As %String, pNamespaces As %String = "") As %Status [ Internal ]
{
	New $namespace
	Set tSC = $$$OK
	Try {
		Kill pMirNamespaces
		Set pMirNamespaces = ""
		If $namespace '= "%SYS" {
			Set $namespace="%SYS"
		}
		Set Rset=##class(%ResultSet).%New("Config.Namespaces:List")
		If Rset="" s tSC=%objlasterror q
		If pNamespaces="" {
			Set tSC=Rset.Execute()
		} Else {
			Set tSC=Rset.Execute(pNamespaces)
		}
		If '$$$ISOK(tSC) q
		While Rset.Next() {
			Set tNamespace = Rset.Get("Namespace")
			If '$data(^%SYS("Ensemble","InstalledNamespace",tNamespace))&&'$data($$$InteropSystemNamespace(tNamespace))&&(pNamespaces="") continue
			If $s($d(mdb(Rset.Get("Globals")),mir):mir,1:$$ismdb(Rset.Get("Globals")))||
			   $s($d(mdb(Rset.Get("Routines")),mir):mir,1:$$ismdb(Rset.Get("Routines")))||
			   $s($d(mdb(Rset.Get("System Globals")),mir):mir,1:$$ismdb(Rset.Get("System Globals")))||
			   $s($d(mdb(Rset.Get("System Routines")),mir):mir,1:$$ismdb(Rset.Get("System Routines")))||
			   $s($d(mdb(Rset.Get("Library")),mir):mir,1:$$ismdb(Rset.Get("Library")))||
			   $s($d(mdb(Rset.Get("Temp Storage")),mir):mir,1:$$ismdb(Rset.Get("Temp Storage"))) {
				Set pMirNamespaces(tNamespace) = "" 
			} Else {
				Set Namespaces(tNamespace)=""
			}
		}
		If '$d(Namespaces) Quit
		Set Namespace=""
		For  {
			s Namespace=$o(Namespaces(Namespace)) q:Namespace=""
		 	s Found=0
		 	Set Rset=##class(%ResultSet).%New("Config.MapGlobals:List")
		 	i Rset="" {
			 	s tSC=%objlasterror
			 	q
		 	}
		 	s tSC=Rset.Execute(Namespace)
			i '$$$ISOK(tSC) q
			While Rset.Next() {
				i $s($d(mdb(Rset.Get("Database")),mir):mir,1:$$ismdb(Rset.Get("Database")))||
				  $s($d(mdb(Rset.Get("Database")),mir):mir,1:$$ismdb(Rset.Get("LockDatabase"))) {
					Set pMirNamespaces(Namespace) = ""
					Set Found=1
					Quit
				}
			}
			i Found continue
#;Now do routines
		 	Set Rset=##class(%ResultSet).%New("Config.MapRoutines:List")
		 	i Rset="" {
			 	s tSC=%objlasterror
			 	q
		 	}
		 	s tSC=Rset.Execute(Namespace)
			i '$$$ISOK(tSC) q
			While Rset.Next() {
				i $s($d(mdb(Rset.Get("Database")),mir):mir,1:$$ismdb(Rset.Get("Database"))) {
					Set pMirNamespaces(Namespace) = ""
					Set Found=1
					Quit
				}
			}
			i Found continue
#;Now do Packages
		 	Set Rset=##class(%ResultSet).%New("Config.MapPackages:List")
		 	i Rset="" {
			 	s tSC=%objlasterror
			 	q
		 	}
		 	s tSC=Rset.Execute(Namespace)
			i '$$$ISOK(tSC) q
			While Rset.Next() {
				i $s($d(mdb(Rset.Get("Database")),mir):mir,1:$$ismdb(Rset.Get("Database"))) {
					Set pMirNamespaces(Namespace) = ""
					Set Found=1
					Quit
				}
			}
		 }
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
ismdb(dbname)
	s rc=##Class(Config.Databases).Get(dbname,.dbprop)
	if '$$$ISOK(rc) {
		s mdb(dbname)=0
		quit 0
	}
	s Obj=##Class(SYS.Database).%OpenId(dbprop("Directory"),,.rc)
	i '$$$ISOK(rc) {
		s mdb(dbname)=0
		quit 0
	}
	s mdb(dbname)=''Obj.Mirrored
	k Obj
	q mdb(dbname)
}

ClassMethod Install(pUpgrade As %Boolean = 0, pProduct As %String = "", pSrcDir As %String = "") As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#;These 2 cleaned up at the end of CheckForInstall()
		Set ^%SYS("Ensemble","RunOnce","InitializeEnsemble")=pProduct
		Set ^%SYS("Ensemble","RunOnce","InitializeEnsemble","Upgrade")=pUpgrade
	
		 // Set ^%SYS("Ensemble","CSPAppSec") at installation time
		Set CSPAppSec = ..DetermineCSPAppSec()
	
		// Define Interoperability auditing events at installation or upgrade time
		Do ..CreateEnsembleAuditingEvents()
	
		If 'pUpgrade {
			// Enable Production AutoStart for a new Interoperability/HS installation
			Set tSC = ..configureEnsembleAutoStart(1)
		}
		If (",irishealth,healthshare,healthconnect,"[(","_$ZCVT(pProduct,"L")_","))  {
			// HealthShare pre-setup
			Set ^%SYS("HealthShare")=pUpgrade_"^"_pProduct
			/// container upgrades no longer have the installation kit so look in the installdir
			Set tHSUtilFileToLoad = ""
			Set tHSUtilFile = ##class(%File).NormalizeFilename($system.Util.InstallDirectory()_"dist/install/misc/hsutil.xml")
			If ##class(%File).Exists(tHSUtilFile) {
				Set tHSUtilFileToLoad = tHSUtilFile 
			} ElseIf ##class(%File).Exists(pSrcDir_"hsutil.xml") {
				Set tHSUtilFileToLoad =  pSrcDir_"hsutil.xml" 
			}
			If tHSUtilFileToLoad]"" {
				Set tSC = $system.OBJ.Load(tHSUtilFileToLoad,"ck-d")
				If $$$ISERR(tSC) {
					Write !,"ERROR: Import of '"_tHSUtilFileToLoad_"' failed: "_$system.Status.GetErrorText(tSC)
				} Else {
					Write !,"Loaded hsutil.xml successfully"
				}
			}
			//bump routine cache for new installs
			If 'pUpgrade {
				Do ##class(%ZHSLIB.HealthShareMgr).PreInstallSetup()
			} ElseIf $$$comMemberDefined("%ZHSLIB.HealthShareMgr",$$$cCLASSmethod,"PreUpgradeSetup") {
				// DMC1165: Call PreUpgradeSetup() as per Keshav
				Do ##class(%ZHSLIB.HealthShareMgr).PreUpgradeSetup()
			}
		}
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod configureEnsembleAutoStart(pValue As %Boolean = 1) As %Status
{
	#dim tSC As %Status
	#dim tProperties
	Set tProperties("EnsembleAutoStart") = ''pValue
	Set tSC = ##class(Config.Startup).Modify(.tProperties,,$$$CPFSave+$$$CPFWrite)
	Quit tSC
}

/// Initialize HealthShare
ClassMethod InitializeHealthShare(pVerbose As %Boolean = 0, pHSLib As %String = {..#HSLIB}, ByRef pIsPrimary As %Boolean = 1) As %Status
{
	try {
		Set tSC=##class(%ZHSLIB.HealthShareMgr).InitializeHealthShare(pVerbose,pHSLib,.pIsPrimary)
	} catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod getVersion() As %List
{
	Quit $LB(+$system.Version.GetMajor(), +$system.Version.GetMinor(), +$system.Version.GetPoint(), +$system.Version.GetBuildNumber(), +$system.Version.IsUnicode(), $e($p($p($p($zv,"Build ",2),")",1),"U",1),$l($system.Version.GetBuildNumber())+1,*))
}

ClassMethod getVersionIdentifier() As %String [ Internal, Private ]
{
	#dim tVersion As %String
	
	Set tVersion = $system.Version.GetNumber()
	Set:$P(tVersion,".",3)="" $P(tVersion,".",3)=0
	
	Set tVersion = tVersion_"."_$system.Version.GetBuildNumber()
	Set:$system.Version.IsUnicode() tVersion = tVersion_"U"
	
	Quit tVersion
}

ClassMethod InitializeEnsemble(pVerbose As %Boolean = 0, ByRef pIsPrimary As %Boolean = 1) As %Status [ PublicList = InstallBootStrap ]
{
	New InstallBootStrap
	;
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	;
	;
	; We need to add the library database and database to the system:
	; 	ENSLIB	- Main Interoperability Library (database only)
	; 
	; In addition, we need to make sure that all Interoperability code and localised 
	; data are mapped to all namespaces.
	; 
	; Finally, we create a CSP application for the Interoperability Management Portal in each namespace.
	;

	#dim tEnsLib = ..#ENSLIB
	;
	#dim tNamespaceProductionType = ..namespaceProductionType()

	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	If '$Data(%Log) New %Log Set %Log=$IO

	Try {

		; We can only run this in %SYS
		If $NAMESPACE'="%SYS" {
			Use:$G(%Log)'="" %Log
			$$$REPORT(0,"InitializeEnsemble: Must be in %SYS (currently in "_$NAMESPACE_")")	
			Set tSC = $$$ERROR($$$GeneralError,"Must be in %SYS")
			Quit
		}
		;
 		Do ##class(%SYS.System).WriteToConsoleLog("","Updating for "_tNamespaceProductionType_" installation")
		;
	 	#dim tCfgName = ##class(%SYS.System).GetInstanceName()
	 	#dim tCfgFile = ##class(%SYS.System).GetCPFFileName()
	 	#dim tCfgDir  = $System.Util.DataDirectory()
		#dim tEnsLibDir = ..GetENSLIB(0,0)
		#dim tInstallationMgrDir =  ##class(%File).SubDirectoryName($System.Util.InstallDirectory(),"mgr")
		#dim tMgrDir = $System.Util.ManagerDirectory()

		// Normalize the config file for VMS
		Set tCfgFile = ##class(%File).NormalizeFilename(tCfgFile)

		$$$REPORT(0,"Updating for "_tNamespaceProductionType_" installation:")

		#dim tReportVersion
		Try {
			Set tReportVersion = ##class(%ZHSLIB.HealthShareMgr).VersionInfo()
		} Catch {
			Set tReportVersion = $System.Version.GetVersion()
		}

		/*
			Check if we are in a container marked as "IsDeployed"
				This means that enslib & irislib directories are
				inside the container and ought to be marked read only
				at the file system and hence cannot be mounted RW.
		*/
		#dim tCanMakeLIBDBsRW = '$SYSTEM.Container.IsDeployed()
		#dim tIsUpgrade = $Get(^%SYS("Ensemble","RunOnce","InitializeEnsemble","Upgrade"),0)

		$$$REPORT(4,"* Configuration:")
		$$$REPORT(6,"- System Libraries Parent Directory:"_tInstallationMgrDir)
		$$$REPORT(6,"- Manager Directory:                "_tMgrDir)
		$$$REPORT(6,"- Configuration Name:               "_tCfgName)
		$$$REPORT(6,"- Configuration Directory:          "_tCfgDir)
		$$$REPORT(6,"- Version:                          "_tReportVersion)
		$$$REPORT(6,"- Upgrade:                          "_$Select(tIsUpgrade:"Yes",1:"No"))

		Set tSC = ##class(Config.CPF).Read(,$$$CPFImport)
		Use %Log

		If $$$ISERR(tSC) $$$REPORT(0,"ERROR: Import of '"_tCfgFile_"' failed: "_$system.Status.GetErrorText(tSC))

		$$$REPORT(4,"* Storage:")

		#; No longer add ENSEMBLE
		$$$REPORT(6,"- "_tEnsLib)

		#dim properties
		If '##Class(Config.Databases).Exists(tEnsLib) {

			$$$REPORT(8,"+ Adding Database: "_tEnsLib_" in "_tEnsLibDir)
			Set properties("Directory")=tEnsLibDir
			Set tSC=##Class(Config.Databases).Create(tEnsLib,.properties,,$$$CPFSave+$$$CPFWrite+$$$CPFActivate+$$$CPFAvoidBackupDB)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to add database: "_$system.Status.GetErrorText(tSC))
				Quit
			}

		} Else {

			$$$REPORT(8,"+ Database "_tEnsLib_" already exists ... skipping")

		}

		#dim tEnsLibRW = 0
		If tCanMakeLIBDBsRW {
			/*
				ENSLIB will be marked Read Write if resource is set.
				Record initial Read Only setting to ensure
				exit with same value.
			*/
			Set tSC = ..getDBRWFlag(tEnsLibDir,.tEnsLibRW)
			If $$$ISERR(tSC) {
				$$$REPORT(8,"ERROR: Failed to obtain R/W flag for '"_tEnsLibDir_"': "_$system.Status.GetErrorText(tSC))
			} ElseIf 'tEnsLibRW {
				$$$REPORT(8,"+ ENSLIB is marked as Read Only and will be set back to Read Only after Initialization")
			} Else {
				$$$REPORT(8,"+ ENSLIB is marked as Read Write and will be left as Read Write after Initialization")
			}
		} Else {
			$$$REPORT(8,"+ Not modifying library databases due to Container deployed mode.")
		}

		If '..#CREATEENSLIBNAMESPACE {
			#; Remove ENSLIB namespace if it already exists and no mappings exist
			#dim tEnsLibNS As Config.Namespaces
			If ..#REMOVEEENSLIBNAMESPACE && ##class(Config.Namespaces).Exists(tEnsLib, .tEnsLibNS) {
				#dim tHasMaps = 0
				#dim tProp
				For tProp = "Globals", "Routines" {
					If $property(tEnsLibNS, tProp) '= tEnsLib {
						Set tHasMaps = 1
						Quit
					}
				}
				If 'tHasMaps {
					#dim tMapType
					For tMapType = "Config.MapGlobals", "Config.MapPackages", "Config.MapRoutines" {
						Set tRS = ##class(%ResultSet).%New(tMapType_":List")
						Set tSC = tRS.Execute(tEnsLib,"*")
						If $$$ISOK(tSC) && tRS.Next() {
							Set tHasMaps = 1
							Quit
						}
					}
					If 'tHasMaps { // no mappings exist for ENSLIB namespace
						$$$REPORT(8,"+ Removing unnecessary namespace: "_tEnsLib)
						Set tSC = ##class(Config.Namespaces).Delete(tEnsLib)
						If $$$ISERR(tSC) { // Not critical if we can't remove ENSLIB namespace
							$$$REPORT(0,"ERROR: Failed to delete namespace: "_$system.Status.GetErrorText(tSC))
						}
					}
				}

			}

		} ElseIf '##Class(Config.Namespaces).Exists(tEnsLib) {

			$$$REPORT(8,"+ Creating Namespace: "_tEnsLib)
			Kill properties
			Set properties("Globals")=tEnsLib
			Set tSC=##Class(Config.Namespaces).Create(tEnsLib,.properties)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to create namespace: "_$system.Status.GetErrorText(tSC))
			}

		} Else {

			$$$REPORT(8,"+ Namespace "_tEnsLib_" already exists ... skipping")

		}

		// Create a database resource for ENSLIB et. al.
		$$$REPORT(4,"* Security:")

		#; ENSLIB db ought not to be mirrored
		If pIsPrimary || '$data(pIsPrimary("MirrorNS", tEnsLib)) {

			/*
				If the database label resource field is updated then
				the database will be mounted RW.
				Passing in "" for database directory will prevent
				the assignResourceToDB modifying the label and 
				just checking that the resource exists.
			*/
			$$$REPORT(6,"- Creating resource %DB_ENSLIB for "_tEnsLib)
			#dim tDBPermissions = "R"
			If tCanMakeLIBDBsRW {
				Set tSC = ..assignResourceToDB("%DB_ENSLIB",tEnsLibDir,tDBPermissions)
			} Else {
				Set tSC = ..assignResourceToDB("%DB_ENSLIB","",tDBPermissions)
				/* Try to mount ENSLIB if not mounted since we did not attempt to change the volume label */
				#Dim tEnsLibDBobj = ##class(SYS.Database).%OpenId(tEnsLibDir)
				If $IsObject(tEnsLibDBobj) {
					If '(tEnsLibDBobj.Mounted) {
						Set tSC = tEnsLibDBobj.Mount()
						If $$$ISERR(tSC) || '(tEnsLibDBobj.Mounted) {
							$$$REPORT(0,"WARNING: Failed to mount '"_tEnsLibDir_"'."_$S($$$ISERR(tSC):$system.Status.GetErrorText(tSC),1:""))
						}
					}
				} Else {
					$$$REPORT(0,"WARNING: Failed to open '"_tEnsLibDir_"'")
				}
				Set tEnsLibDBobj = ""
			}
			Use %Log
			If $$$ISERR(tSC) {
				$$$REPORT(8,"ERROR: "_$system.Status.GetErrorText(tSC))
			}

		} Else {
			$$$REPORT(6,"- Skipping resource creation for namespace "_tEnsLib_" as it contains mirrored data")
		}

		#dim tUsername="_Ensemble"
		#dim tEnsUser, tEnsUserProperty

		If ##class(Security.Users).Exists(tUsername,.tEnsUser) {

			$$$REPORT(6,"- Username '"_tUsername_"' already exists.")

			Try {
				For tEnsUserProperty = "AccountNeverExpires","PasswordNeverExpires" {
					If $PROPERTY(tEnsUser,tEnsUserProperty) = 0 {
						Set $PROPERTY(tEnsUser,tEnsUserProperty) = 1
						Set tSC = tEnsUser.%Save()
						If $$$ISOK(tSC) {
							$$$REPORT(8,"- Set property '"_tEnsUserProperty_"' to True.")
						} Else {
							$$$REPORT(8,"- Failed to set property '"_tEnsUserProperty_"' to True.")
							Do $system.OBJ.DisplayError(tSC)
						}
					} Else {
						$$$REPORT(8,"- Property '"_tEnsUserProperty_"' already set to True.")
					}
				}
			} Catch ex {
				$$$REPORT(8,"- Errored setting properties 'AccountNeverExpires' and 'PasswordNeverExpires' to True.")
				Do $system.OBJ.DisplayError(ex.AsStatus())
			}

		} Else {

			// Create with AccountNeverExpires and PasswordNeverExpires set to True
			Set tSC=##Class(Security.Users).Create(tUsername,"%All",$c(0,0),(tNamespaceProductionType_" Manager (Internal use - not for login)"),/*NameSpace*/,/*Routine*/,/*ExpirationDate*/,/*ChangePassword*/,/*Enabled*/,/*Comment*/,/*Flags*/,/*PhoneNumber*/,/*PhoneProvider*/,/*Attributes*/,1 /*AccountNeverExpires*/,1 /*PasswordNeverExpires*/)
			If $$$ISOK(tSC) {
				$$$REPORT(6,"- Username '"_tUsername_"' created successfully with properties 'AccountNeverExpires' and 'PasswordNeverExpires' set to True.")
			} Else {
				$$$REPORT(6,"- Username '"_tUsername_"' failed to be created.")
			}

		}

		// Add Resources, Roles, and upgrade existing users if necessary
		Set tSC = ..InstallEnsembleSecurity(pIsPrimary, pVerbose)
		Quit:$$$ISERR(tSC)

		$$$REPORT(6,"- Configuration "_tCfgName_" updated.")

		If tIsUpgrade {

			Kill ^%SYS("Ensemble","InstalledNamespace","ENSDEMO")

		} Else {

			If $$PlatformId^%SYS.LICENSE()=66 {
				/// if New install for Community enable the USER namespace
				Set tSC = ##class(%EnsembleMgr).EnableNamespace("USER",1,.pIsPrimary,1,tIsUpgrade)
			}

		}
		
		#; Create the IRISMETRICS database if it does not exist.
		#; This must occur before Upgrade()
		Set tSC1 = ..CreateNewDBForMetrics(pVerbose)
		If $$$ISERR(tSC1) {
			$$$REPORT(0,"Creation of new database 'IRISMETRICS' for interoperability metrics failed.  Try running ##class(%EnsembleMgr).InitializeEnsemble() again to correct.")
		}

		// And upgrade any existing production-enabled namespaces
		Set tSC = ..Upgrade(pVerbose, .pIsPrimary)
		Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)

 		// Now, walk the list of known namespaces and make sure they are all production-enabled
		$$$REPORT(4,"* "_tNamespaceProductionType_" enabling namespaces")
		#dim tNS = ""
		For {
			Set tNS = $O(^%SYS("Ensemble","InstalledNamespace",tNS)) Quit:tNS=""

			$$$REPORT(6,"- Enabling namespace: "_tNS)
			
			// Enable each namespace
			Set tSC = ##class(%EnsembleMgr).EnableNamespace(tNS,1,.pIsPrimary,1,tIsUpgrade)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}

		Set tSC = ..loadENSLIBMessages(tEnsLibRW, tEnsLibDir, pVerbose)
		Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)

		$$$REPORT(0,"Update Complete.")

		// Mark when we last did an InitializeEnsemble()
		Set ^%SYS("Ensemble") = $ZDT($H,3)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If $$$ISERR(tSC) {
		// Report any errors
		Do ##class(%SYS.System).WriteToConsoleLog("",tNamespaceProductionType_" update failed: "_$system.Status.GetErrorText($G(tSC,$$$OK)))
		Use %Log $$$REPORT(0,"ERROR: EnsUpdate failed: "_$system.Status.GetErrorText(tSC))
		Do $system.OBJ.DisplayError(tSC)
	}
	Return tSC
}

/// Validate an Interoperability installation in ENSLIB
ClassMethod ValidateEnsemble(pEnsLib As %String = {..#ENSLIB}, pVerbose As %Boolean = 0) As %Status
{
	// Make sure that ENSLIB is valid
	Set tCheck("Ens.Director")=""
	Set tCheck("Ens.StudioManager")=""
	Set tCheck("Ens.MessageBody")=""
	If ##class(%Dictionary.ClassDefinition).%ExistsId("%ZHSLIB.HealthShareMgr") {
		Set tCheck("EnsLib.HL7.Message")=""
	}
	Quit ..validateInstallation(pEnsLib, .tCheck, pVerbose)
}

/// Validate an installation by checking for specific classes in a namespace
ClassMethod validateInstallation(pNS As %String, ByRef pCheck, pVerbose As %Boolean = 0) As %Status [ Internal, Private ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set $ZT="Trap",tSC=$$$OK
	New $namespace
	Do {
		$$$REPORT(4,"* Validating Installation in '"_pNS_"'")
		
		Set $namespace = pNS
		
		Set tClass = ""
		For {
			Set tClass = $O(pCheck(tClass))
			Quit:tClass=""

			$$$REPORT(6,"- Checking class '"_tClass_"' ...")

			// Check to see if the class exists ...
			If '##class(%Dictionary.CompiledClass).%ExistsId(tClass) {
				// It's missing
				$$$REPORT(8,"- CLASS IS MISSING!")
				Set tSC2 = $$$ERROR($$$ClassDoesNotExist,tClass)
				Set tSC = $$$ADDSC(tSC, tSC2)
				Continue
			}

			// Check for the class descriptor
			If '##class(%Library.RoutineMgr).Exists(tClass_".0.OBJ") {
				// It's missing
				$$$REPORT(8,"- CLASS DESCRIPTOR IS MISSING!")
				Set tSC2 = $$$ERROR($$$RoutineDoesNotExist,tClass_"0.OBJ")
				Set tSC = $$$ADDSC(tSC, tSC2)
				Continue
			}
			
			// This one looks good ...
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)	
	Goto Exit
}

ClassMethod Upgrade(pVerbose As %Boolean = 0, ByRef pIsPrimary As %Boolean = 1) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$REPORT(4,"* Upgrading existing namespaces")

		// Recover list of pre-4.0 namespaces to upgrade		
		Merge tNSList = ^|"%SYS"|SYS("Ensemble","InstalledNamespace")
		Merge tNSList = ^%SYS("Ensemble","InstalledNamespace")
		
		Set tNS = ""
		For {
			Set tNS = $O(tNSList(tNS)) Quit:tNS=""
			
			// Upgrade this namespace		
			Set tSC = ..UpgradeNamespace(tNS,pVerbose,.pIsPrimary)
			If $$$ISERR(tSC) {			
				Do $system.OBJ.DisplayError(tSC)
			}
		}
		// Don't block the rest of the upgrade for any failures in porting Interop Metrics data
		Set tSC1 = ##class(SYS.Monitor.Interop.Interface.Utils).Upgrade()
		If $$$ISERR(tSC1) {
			$$$REPORT(6,"Upgrade of Interoperability Metrics data failed : "_$System.Status.GetErrorText(tSC1))   
		}
		
	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod UpgradeNamespace(pNS As %String, pVerbose As %Boolean = 0, ByRef pIsPrimary As %Boolean = 1) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	// Check for namespace validity including if it can be accessed
	Quit:'..validateNamespace(.pNS,0,.tSC,1) tSC

	// We don't "upgrade" ENSLIB ever
	If (pNS = ..#ENSLIB) Quit $$$OK

	Set $ZT="Trap",tSC=$$$OK
	Do {
		$$$REPORT(6,"- Upgrading namespace: "_pNS)
		New $NAMESPACE
		Set $NAMESPACE = pNS
		
		If (pIsPrimary)||('$data(pIsPrimary("MirrorNS",pNS))) {
			// Build the qualifiers: Note we must do this in a real namespace and also we can't
			// display anything since there is no access to ^%qMsg, hence we use -d.
			Set tSC = $$$qualifierParse("Compiler","-d",.qstruct)
			Quit:$$$ISERR(tSC)
		
			// Upgrade the namespace
			$$$REPORT(8,"+ Upgrading class dictionary")
			Set tSC = $$Upgrade^%occConvert(.qstruct)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		
			If $D(^|"%SYS"|SYS("Ensemble","InstalledNamespace",pNS)) {
				Set tSC = ..cleanupOldNamespace(pNS,pVerbose)
				Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
			}
			/* 
				Flags that need to be set during upgrade can be set here. 
				Check version upgrading from by looking at Ens.Mirror("Version")
					Set tOldVersion = $get(^Ens.Mirror("Version"))
					Set tMajorVersion = $listget(tOldVersion,1)
					Set tMinorVersion = $listget(tOldVersion,2)
					If (tOldVersion="")||(tMajorVersion<2014) {
						$$$REPORT(8,"+ Setting XXXX flag for existing namespace")
						Set ^Ens.Config("Example")=1
					}
			*/
			
			// Build the Extent index for Ens.BusinessProcess, if it has not been built yet
			If '$Data(^Ens.BusinessProcessI("Extent")) {
				Set tSC = ##class(Ens.BusinessProcess).%BuildIndicesAsync(,$LISTBUILD("Extent"))
				Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
			}

			// Build the Ens_Enterprise_MsgBank.MessageHeader indices introduced in 2025.1, if they have not been built yet
			If ('$D(^Ens.EntMsgBank.MessageHeaderI("SrcN"))) || ('$D(^Ens.EntMsgBank.MessageHeaderI("TrgN")))
					|| ('$D(^Ens.EntMsgBank.MessageHeaderI("NodeSourceTime"))) || ('$D(^Ens.EntMsgBank.MessageHeaderI("NodeTargetTime")))
					|| ('$D(^Ens.EntMsgBank.MessageHeaderI("MessageBodyNode"))) {
				Set indices = $LB("SrcN", "TrgN", "NodeSourceTime", "NodeTargetTime", "MessageBodyNode")
				Set tSC = ##class(Ens.Enterprise.MsgBank.MessageHeader).%BuildIndicesAsync(,indices)
				Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
			}
		} Else {
			$$$REPORT(8,"+ Skipping class dictionary upgrade for namespace "_pNS_" as it contains mirrored data")
		}
		
		// Remove any current mappings to ENSLIB
		Set tSC = ..unmap2enslib(pNS,pVerbose)
		Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		
		// Note, once we're done, we'll reactivate this namespace and apply the current mappings
		
	} While(0)
Exit
	// Make sure we switch back to the original namespace
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod cleanupOldNamespace(pNS As %String, pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set tSC=$$$OK,$ZT="Trap"
	New $NAMESPACE
	Do {
		$$$REPORT(4,"* Cleaning up "_pNS)
	
		// Build up a list of databases for this namespace
		Do finddatabases(pNS,.tDBList,pVerbose)

		// For each mapped database, go clean it up		
		Set tDB="" For {
			set tDB=$o(tDBList(tDB),1,pNS) Quit:tDB=""
				
			// For each database, switch to the implied namespace so we avoid any mappings
			$$$REPORT(8,"+ Cleaning database: "_tDB)
			
			// Switch to the database (using $NAMESPACE seems to set up default system mappings properly)
			Set $NAMESPACE = tDB
			
			// Now, delete the old packages
			$$$REPORT(10,"* Deleting obsolete packages:")
			Set tCount=0
			For tPkg = "Ens", "EnsLib", "CSPX", "Demo" {
				
				// Check for the package
				If $$$qualifierParse("Export","d-",.qstruct)
				Set qstruct("includesubpackages")=0
				Do GetPackageList^%occLibrary(.tPkgList,tPkg,.qstruct)
				
				If $D(tPkgList)'<10 {
				
					$$$REPORT(12,"- "_tPkg_".*")
					Set tSC = $system.OBJ.DeletePackage(tPkg,.qstruct)
					If $$$ISERR(tSC) {
						Do $system.OBJ.DisplayError(tSC)
					} Else {
						Set tCount = tCount + 1
					}
				}
			}
			
			$$$REPORT(12,"  [Removed "_tCount_" obsolete package(s)]")
			
			$$$REPORT(10,"* Deleting obsolete routines:")
			
			// And the routines
			Set tRtn="",tCount=0
			For {
				Set tRtn = $O(^rINDEX(tRtn))
				Quit:tRtn=""
				
				If tRtn'[".",tRtn?1"Ens"1.E {
					
					Set tExt = ""
					For {
						Set tExt = $O(^rINDEX(tRtn,tExt))
						Quit:tExt=""
						
						// Delete these
						$$$REPORT(12,"- "_tRtn_"."_tExt)
						Set tSC = $$Delete^%apiRTN(tRtn_"."_$S(tExt="OBJ":"INT",1:tExt),0,0)
						If $$$ISERR(tSC) {
							Do $system.OBJ.DisplayError(tSC)
						} Else {
							Set tCount = tCount + 1
						}
					}
				}
			}
			
			$$$REPORT(12,"  [Removed "_tCount_" obsolete routines(s)]")

			// And the globals
			$$$REPORT(10,"* Deleting obsolete globals:")
			
			// We assume that any globals we now map from ENSLIB that exist in this database are obsolete
			// and should be purged.
			Do ..getMappedGlobals(.tGblMap)
			Set tGblMap = "", tCount = 0
			For {
				Set tGblMap = $O(tGblMap(tGblMap))
				Quit:tGblMap=""
				
				Set tSubStart = $P(tGblMap,":",2)
				Set tSubEnd = $P(tGblMap,":",3)
				
				Set tGbl = $P(tGblMap,":")
				
				Set tBeginRef = "^"_tGbl_tSubStart
				Set tEndRef = "^"_tGbl_tSubEnd
				
				Set tRef = tBeginRef
			
				// Walk the subscript range (if given) and remove any matching globals
				Do {
					// If the global exists, remove it
					If $D(@tRef) {
						// Delete this
						$$$REPORT(12,"- "_tRef)
						Kill @tRef
						Set tCount = tCount + 1
					}
					
					// Advance the subscript (if given)
					Set tRef = $Q(@tRef)
					
					// Keep going as long as:
					//	1) We don't run off the end
					//	2) The we hit the end ref
				} While ((tRef '= "") && (tRef '] tEndRef))
			}
			
			$$$REPORT(12,"  [Removed "_tCount_" obsolete global(s)]")
		}

		// Mark this in the list of ensemble namespaces, this will have to be separately "enabled"
		Set ^%SYS("Ensemble","InstalledNamespace",pNS)=""
	
		// Clean up the old namespace list
		Kill ^|"%SYS"|SYS("Ensemble","InstalledNamespace",pNS)
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
	
finddatabases(nsp,dblist,pVerbose=0)
	$$$REPORT(8,"+ Analysing mappings")
	#;SML1565+
	Set nspinfo=$zu(90,28,2,nsp)
	If nspinfo="" quit
	Kill gxlatinfo
	#; Argument flags 1 - NoSLM, 2 - exact match for global name.
	Do getgxlatarray^%SYS.GXLINFO(.nspinfo,"oddDEF",.gxlatinfo,2)
	If '$Data(gxlatinfo) {
		#; quit if the namespace has been removed.
		If nspinfo="" Quit
		#; The oddDEF does mapping does not exist in the namespace.
		Set dblist("^^"_$zu(90,7,$p(nspinfo,"|",2)))=nsp
		Quit
	}
	Set slm=$List(gxlatinfo,3)
	If slm="" {
		#; No SLM mapping for this globa entry. Set it with the global mapping.
		Set dblist("^^"_$zu(90,7,$p(nspinfo,"|",2)))=nsp
		#; The id is the ^oddDEF mapped to in thw namespace.
		Set id=$Piece($List(gxlatinfo,2),"|",3)
		If id {
			Set db=$zutil(90,7,id)
			If db'="" Set dblist("^^"_db)=nsp
		} else {
			#; The ^oddDEF is not mapped to any DB then set it with default DB.
			Set dblist("^^"_$zu(90,7,$p(nspinfo,"|",2)))=nsp
		}
		Quit
	}
	For k=0:1:($piece($List(slm,1),"|")-1) {
		Set id=$piece($List(slm,k*2+3),"|",1)
		If id {
			Set db=$zutil(90,7,id)
			If db'="" Set dblist("^^"_db)=nsp
		} else {
			Set id=$Piece($List(gxlatinfo,2),"|",3)
			If id s dblist("^^"_$zu(90,7,id))=nsp
		}
	}
	#;SML1565-
	
	// Ignore any databases belonging to these namespaces, since they are mapped by us
	For prune = "IRISLIB","IRISSYS","ENSLIB","IRISMETRICS" {
		Set db=$$DatabaseByName^%SYS.CONFIG(prune)
		If db'="" Kill dblist(db) $$$REPORT(10,"* Ignoring mappings from: "_prune)
	}
	For prune = ..#HSLIB {
		Set dbid = $zu(90,3,1,prune)
		If +dbid {		
			Set db = $zu(90,7,dbid)
			Kill dblist("^^"_db)
		
			$$$REPORT(10,"* Ignoring mappings from: "_prune_$S('dbid:" (not present)",1:""))
		}
	}
	
	Quit
}

/// The following parameters are for internal use:<br/>
/// <li> pIsPrimary can be an array and will be calculated if not passed in</li>
/// Top node is whether this is a primary node or not. It is true if not in a mirror.<br/>
/// Subscripts are namespaces that have one or more mirrored databases.<br/>
/// <li> pFromInstall indicates it is enabling all the existing production-enabled namespaces.</li>
/// <li> pUpgrade only has meaning when pFromInstall is true.</li> <br/>
/// The following parameters are for internal use by %Installer:<br/>
/// <li> pPortalSuffix: InterSystems IRIS portal suffix.</li>
/// <li> pPortalPrefix: InterSystems IRIS portal prefix.</li>
/// <li> pGrant: Resource(s) granted when logged in.</li>
/// <li> pCookiePath: InterSystems IRIS portal cookie path.</li>
/// <li> pAuthMethods: Authentication flags (4=Kerberos, 32=Password, 64=Unauthenticated).</li>
ClassMethod EnableNamespace(pTargetNS As %String, pVerbose As %Boolean = 0, ByRef pIsPrimary, pFromInstall = 0, pUpgrade = 0, ByRef pPortalSuffix As %String = "", ByRef pPortalPrefix As %String = "", pGrant As %String = "", pCookiePath As %String = "", pAuthMethods As %String = "") As %Status
{
	// Check for namespace validity including if it can be accessed
	Quit:'..validateNamespace(.pTargetNS,0,.tSC,1) tSC
	;

	Set $ZT="Trap",tSC=$$$OK
	If '$Data(%Log) New %Log Set %Log=$IO

	; Change namespace to "%SYS"
	New $NAMESPACE
	Set $NAMESPACE = "%SYS"
	
	;
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	;
	; Here, we need to make sure that Ens.* and EnsLib.* classes
	; and Ens*.INC includes are mapped to the target namespace
	; 
	; Finally, we create a CSP application for the Interoperability
	; Management Portal.
	;
	Set tEnsLib = ..#ENSLIB
	Set pTargetNS = $zcvt(pTargetNS,"U")
	#dim tNamespaceProductionType = ..namespaceProductionType()
	;
	Do {
		// Remember the existing portal suffix (if any)
		If pPortalSuffix = "" {
			Set pPortalSuffix = $G(^%SYS("Ensemble","InstalledNamespace",pTargetNS))
		}
		Set tHealthShareCookiePath = "/csp/healthshare/"
		Set tHealthSharePortalPrefix = "healthshare"
		Set tOKToResetCookiePath = (pCookiePath="") && ((pPortalSuffix="") || ($E(pPortalSuffix,1,$L(tHealthShareCookiePath))=tHealthShareCookiePath))
		Set tHealthShareInstalled = ..IsHealthShareInstalled()
		If pFromInstall {
			If ..IsHealthShareNamespace(pTargetNS) {
				Set:(pPortalPrefix="") pPortalPrefix = tHealthSharePortalPrefix
				Set:tOKToResetCookiePath pCookiePath = tHealthShareCookiePath
			}
		} ElseIf tHealthShareInstalled {
			Set:(pPortalPrefix="") pPortalPrefix = tHealthSharePortalPrefix
			Set:tOKToResetCookiePath pCookiePath = tHealthShareCookiePath
		}
 		Do $zu(9,"","Enabling namespace '"_pTargetNS_"' for "_tNamespaceProductionType)
		$$$REPORT(0,"Enabling namespace '"_pTargetNS_"' for "_tNamespaceProductionType_":")
	
 		Set tIsNewNamespace = '$D(^%SYS("Ensemble","InstalledNamespace",pTargetNS))
		// Mark this namespace as production enabled. This needs to be set before calling findMirroredNamespaces which called from populatePrimary
		Set ^%SYS("Ensemble","InstalledNamespace",pTargetNS)=pPortalSuffix
	
		/* 
			Complete pIsPrimary based on what is passed in 
			Top node is whether this is a primary node or not.
			It is set to true if not in a mirror
			If it is in a mirror and not primary then find mirrored namespaces.
		*/
		Set tSC = ..populateIsPrimary(.pIsPrimary)
		Quit:$$$ISERR(tSC)
		Set tIsMirrorMember = $system.Mirror.IsMember()
		If tIsMirrorMember {
			$$$REPORT(2,"* This instance is "_$S(pIsPrimary:"a primary mirror",1:"not a primary mirror"))
			If $D(pIsPrimary("MirrorNS",pTargetNS)) $$$REPORT(2,"+ This namespace has one or more mirrored databases.")
		} Else {
			$$$REPORT(2,"* This instance is not in a mirror")
		}
		
		$$$REPORT(4,"* Mappings")
		Set tSC = ..createMappings(pTargetNS,tEnsLib,pVerbose,.pIsPrimary)
		Quit:$$$ISERR(tSC)
 
		// Validate the mappings
		Set tSC = ..ValidateEnsemble(pTargetNS,pVerbose)
		Quit:$$$ISERR(tSC)

		/// Mark as healthshare namespace when HealthShare is installed and this is not currently a healthshare namespace
		If tHealthShareInstalled && ('pFromInstall && '..IsHealthShareNamespace(pTargetNS)) {
			try {
				Set tSC=##class(%ZHSLIB.HealthShareMgr).EnableHealthShareNamespace(pTargetNS,pVerbose,pIsPrimary,1)
			} catch ex {
				Do $system.OBJ.DisplayError(tSC)
			}
		}
 	
 		$$$REPORT(4,"* Creating "_tNamespaceProductionType_" Management Portal")
 		Set tSC = ..createPortal(pTargetNS,pVerbose,.pPortalSuffix,.pPortalPrefix,pGrant,pCookiePath,pAuthMethods,tEnsLib,.pIsPrimary)
 		Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
 		
 		$$$REPORT(4,"* Adding explicit SQL privileges to "_tNamespaceProductionType_" Roles")
 		Set tSC = ..addEnsembleSQLPrivileges(pTargetNS, pVerbose)
 		Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)

		$$$REPORT(4,"* Modifying Interop Editors API app to use %EnsRole_InteropEditorsAPI role")
 		Set tSC = ..modifyInteropEditorsAPIApp(pTargetNS, pVerbose)
 		Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		
 		If pIsPrimary || '$data(pIsPrimary("MirrorNS",pTargetNS)) {
			Set tSC = ..dataUpgradeSteps(pTargetNS, pVerbose)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
			If tSC,((pFromInstall&&'pUpgrade)||tIsNewNamespace) {
				Kill tFlagsSet
				Set tSC = ..setConfigFlags(.tFlagsSet, pTargetNS, pVerbose)
				Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
			}
 		}
 		Else {
	 		$$$REPORT(4,"* Skipping primary-only upgrade and creation steps, as namespace "_pTargetNS_" contains mirrored data and is not primary.")
 		}
 		/* 
 			Need to create the temporary database whether in a mirror or not and whether primary or not if in a mirror.
 		 	This DB is not journalled
			We do not do USER since could be in a container with Read only directory prior to move to durable location.
 		*/
		If 'tHealthShareInstalled && $$$ISOK(tSC) && ($ZCVT(pTargetNS,"U")'="USER") {
			Set tSC=..createNewDBForEnsTemp(pTargetNS,pVerbose)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}
 		/* 
 			Need to create the secondary database whether in a mirror or not and whether primary or not if in a mirror.
 		 	This DB is journalled. MirrorDBName will be from one copying with SECONDARY appended. MirrorSetName will be the same.
			We do not do USER since could be in a container with Read only directory prior to move to durable location.
 		*/
		If 'tHealthShareInstalled && $$$ISOK(tSC) && ((pFromInstall&&'pUpgrade)||tIsNewNamespace) && ($ZCVT(pTargetNS,"U")'="USER") {
			Set tSC=..CreateNewDBForSecondary(pTargetNS,pVerbose,0)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}
		$$$REPORT(0,"EnableNamespace Complete.")
		
	} While(0)
Exit
	kill tCfg
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	
	Do $zu(9,"",tNamespaceProductionType_" update failed: "_$ZE)
	
	Use %Log $$$REPORT(0,"ERROR: EnsUpdate failed: "_$system.Status.GetErrorText(tSC))
	Do $system.OBJ.DisplayError(tSC)
	Goto Exit
}

/// This method is called after a namespace is deleted
ClassMethod DisableNamespace(pTargetNS As %String, pVerbose As %Boolean = 0, pKeepNamespaceAsSystem As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		// NOTE: We DO NOT remove the mappings etc. here.  We might want to at some point
		//       but the aim of this method is to simply remove the namespace from the
		//		 list of Enabled Namespaces.
		
		// Unmark this namespace as production-enabled
		Set tNamespace = $ZCVT(pTargetNS,"U")
		Kill ^%SYS("Ensemble","InstalledNamespace",tNamespace)
		If pKeepNamespaceAsSystem {
			Set $$$InteropSystemNamespace(tNamespace) = ""
		} Else {
			Kill $$$InteropSystemNamespace(tNamespace)
		}
		Kill ^%SYS("Ensemble","CSPApp",tNamespace)
		
		// Clean up recording of central location for settings report
		#dim tSettingNSP
		#dim tSettingClass = $Order(^%SYS("Ensemble","SettingsReport",""),1,tSettingNSP)
		While tSettingClass'="" {
			If tSettingNSP = pTargetNS Kill ^%SYS("Ensemble","SettingsReport",tSettingClass)
			Set tSettingClass = $Order(^%SYS("Ensemble","SettingsReport",tSettingClass),1,tSettingNSP)
		}

		// Unmark this namespace for HealthShare
		Kill ^%SYS("Ens",tNamespace)
		Kill ^%SYS("HealthShare","Instances",tNamespace)

	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method can be used after making a namespace Interoperability
/// enabled such that it cannot be used to support running a production
/// (for example, does not appear in the Interoperability Management Portal)
/// but the namespace (<parameter>pTargetNS</parameter>) is left with the
/// mappings to ENSLIB
ClassMethod MakeInteropSystemNamespace(pTargetNS As %String) As %Status [ Internal ]
{
	Return ..DisableNamespace(pTargetNS, 0, 1)
}

/// pProductionName argument is the production to start automatically on instance startup 
/// in the namespace given by argument pTargetNS. <br>
/// An empty pProductionName clears any auto-start production in the namespace. <br>
/// Productions are started in descending order of priority followed by alphabetically.<br>
/// pStartupPriority argument is used to set the relative priority for auto start of productions 
/// within the instance. The default is the value 0.<br>
ClassMethod SetAutoStart(pTargetNS As %String, pProductionName As %String, pStartupPriority As %Integer = "") As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		// Check for namespace validity
		Quit:'..validateNamespace(.pTargetNS,1,.tSC)
		
		// Switch namespace
		If $NAMESPACE'=pTargetNS {
			New $NAMESPACE
			Set $NAMESPACE = pTargetNS
		}

		// Delegate to the Ens.Director
		Set tSC = ##class(Ens.Director).SetAutoStart(pProductionName,pStartupPriority)

	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod ApplySettings(pTargetNS As %String, pProductionName As %String, ByRef pSettings) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		// Check for namespace validity
		Quit:'..validateNamespace(.pTargetNS,1,.tSC)
		
		// Switch namespace
		If $NAMESPACE'=pTargetNS {
			New $NAMESPACE
			Set $NAMESPACE = pTargetNS
		}
		
		
		// Delegate to the Ens.Production
		Set tSC = ##class(Ens.Production).ApplySettings(pProductionName,.pSettings)

	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod SetCredential(pTargetNS As %String, pName As %String, pUsername As %String, pPassword As %String, pOverwrite As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		// Check for namespace validity
		Quit:'..validateNamespace(.pTargetNS,1,.tSC)
		
		// Switch namespace
		If $NAMESPACE'=pTargetNS {
			New $NAMESPACE
			Set $NAMESPACE = pTargetNS
		}
		
		// Delegate to the credential class
		Set tSC = ##class(Ens.Config.Credentials).SetCredential(pName, pUsername, pPassword, pOverwrite)

	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Remove all rule cache routines and recompile all business rules.
ClassMethod upgradeRules(pTargetNS As %String, pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set $ZT="Trap",tSC=$$$OK
	Do {
		// Check for namespace validity
		Quit:'..validateNamespace(.pTargetNS,1,.tSC)
		
		// Switch namespace
		If $NAMESPACE'=pTargetNS {
			New $NAMESPACE	
			Set $NAMESPACE = pTargetNS
		}
		
		// Check for duplicate definitions of custom functions
		Set s = ##class(Ens.Rule.Utils).GetAllFunctions(.v)
		If $$$ISOK(s) {
			$$$REPORT(5,"+ Checking for duplicate names in function class definitions ... OK")
		}
		Else {
			$$$REPORT(5,"+ Duplicate function names were found in custom function classes:")
			Do $system.OBJ.DisplayError(s)
		}
		// Convert storage globals from pre-MC680 format
		$$$REPORT(5,"+ Updating storage for rule definitions from any legacy version definitions")
		Set tSC=##class(Ens.Rule.RuleDefinition).ConvertStorageGlobal()
		If $$$ISERR(tSC) Do $system.OBJ.DisplayError(tSC)

		// Try to clear FunctionSet Cache before upgrade, but not critical error if fails because ^Ens.FunctionSet no longer used as of JGM737
		Try { $$$KillRootNode(^Ens.FunctionSet) } Catch { /* we can expect this error will be thrown again at compilation time */}

		#; Ensure all FunctionSet classes are compiled as the Rule classes may need them to compile successfully.
		$$$REPORT(5,"+ Checking for any FunctionSet classes that need to be compiled")
		Set tRS = ##class(%Library.ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("Ens.Rule.FunctionSet")
		If $$$ISERR(tSC) {
			$$$REPORT(8,"- Error finding subclasses: "_$system.Status.GetErrorText(tSC))
		}
		Else {
			Kill tFunctions
			While tRS.%Next() {
				Set tFuncName = tRS.%Get("Name")
				If ("" '= tFuncName) && ("Ens." '= $extract(tFuncName,1,4)) && ("EnsLib." '= $extract(tFuncName,1,7)) && '$data(^oddCOM(tFuncName,$$$cCLASSmethod)) {
					Set tFunctions(tFuncName) = ""
				}
			}
			If '$data(tFunctions) {
				$$$REPORT(8,"- No FunctionSet classes need to be compiled.")
			}
			Else {
				$$$REPORT(8,"- Compiling FunctionSet classes" _ $select(pVerbose: ":", 1: ""))
				#; Ensure we try to (re)compile all FunctionSet classes to ensure that they are available for the rule upgrade and compile
				Set qspec = "/mapped=1/predecessorclasses=1/checkuptodate=all/display="_$select(pVerbose:"all", 1:"none")
				Set tSC = $system.OBJ.Compile(.tFunctions,qspec)
				If $$$ISERR(tSC) Do $system.OBJ.DisplayError(tSC)
			}
		}

		// Upgrading rule definition
		$$$REPORT(5,"+ Upgrading rule definition")
		set tSC=##class(Ens.Rule.Upgrade).ConvertAll("/display="_$s(pVerbose:"all",1:"none"))
		If $$$ISERR(tSC) Do $system.OBJ.DisplayError(tSC)

	} While(0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Internal method to validate a namespace: <br/>
/// Name needs to be non empty and not %SYS. <br/>
/// Needs to be defined as a namespace. <br/>
/// Optional check: If <parameter>pIsEnabled</parameter> is true then require
/// namespace is marked as an Interoperability namespace. <br/>
/// Optional check: If <parameter>pCheckIfAvailable</parameter> is true then require
/// namespace can be accessed.<br/>
ClassMethod validateNamespace(ByRef pTargetNS As %String, pIsEnabled As %Boolean = 0, ByRef pSC As %Status, pCheckIfAvailable As %Boolean = 0) As %Boolean
{
	// Force uppercase
	Set pTargetNS = $ZCVT($G(pTargetNS),"U")

	// Validate name
	If (pTargetNS="") || (pTargetNS="%SYS") {
		Set pSC = $$$ERROR($$$GeneralError,"Namespace '"_pTargetNS_"' is not valid for "_..technologyType())
		Quit 0
	}

	// Check to see if it actually exists at the system level
	If '$ZU(90,3,1,pTargetNS) {
		Set pSC = $$$ERROR($$$NamespaceDoesNotExist,pTargetNS)
		Quit 0
	}

	// Check for a production-enabled namespace if pIsEnabled was specified
	If (pIsEnabled && '$D(^%SYS("Ensemble","InstalledNamespace",pTargetNS))) {
		Set pSC = $$$ERROR($$$NamespaceDoesNotExist,pTargetNS)
		Quit 0
	}

	// Check to see if available
	If (pCheckIfAvailable && '$$FastNSCheck^%SYS.NAMESPACE(pTargetNS,1)) {
		Try {
			#; Find if remote DB for Namespace to report appropriate error message.
			#dim tNSPList
			Do ##class(%CSP.Portal.Utils).%GetNamespaceList(.tNSPList)
			If $Data(tNSPList(pTargetNS)) && $ListGet(tNSPList(pTargetNS),2) {
				#; ECP DB for Namespace
				#dim ECPStatus=$$GetECPStatus^%SYS.NAMESPACE(pTargetNS)
				#dim Status=$Case(ECPStatus,-2:"Invalid connection name",-1:"Invalid",2:"Connection in Progress",3:"Conection Failed",4:"Disabled",6:"Trouble",7:"Recovery",:"???")
				Set pSC = $$$ERROR($$$NamespaceUnavailableECP,pTargetNS,ECPStatus_" - "_Status)
			} Else {
				Set pSC = $$$ERROR($$$NamespaceUnavailable,pTargetNS)
			}
		} Catch {
			#; Default to namespace unavailable
			Set pSC = $$$ERROR($$$NamespaceUnavailable,pTargetNS)
		}
		Quit 0
	}

	Quit 1
}

ClassMethod UpdateAndReloadCPF(pVerbose, pTargetNS) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Try {
		If '$Data(%Log) New %Log Set %Log=$IO
		Set tOldNamespace=$namespace
		Set $namespace="%SYS"
		$$$REPORT(6,"- Updating CPF")
		Set tSC = ##class(Config.CPF).Write()
	 	If $$$ISERR(tSC) {
		 	$$$REPORT(6,"ERROR: Failed to update CPF with new mappings: "_$system.Status.GetErrorText(tSC))
		 	Quit
	 	}
 	
	 	$$$REPORT(6,"- Moving changes to active configuration")
	 	Set tSC = ##class(Config.Map).MoveToActive()
	 	If $$$ISERR(tSC) {
		 	$$$REPORT(6,"ERROR: Failed to move changes to active configuration: "_$system.Status.GetErrorText(tSC))
		 	Quit 
	 	}
 	
	 	$$$REPORT(6,"- Loading new mappings for namespace '"_pTargetNS_"'")
		Set tSC = ##class(Config.Namespaces).Load(pTargetNS)
	 	If $$$ISERR(tSC) {
		 	$$$REPORT(6,"ERROR: Failed to load updated mappings for namespace '"_pTargetNS_"': "_$system.Status.GetErrorText(tSC))
		 	Quit 
	 	}
	} Catch ex {
		Set tSC=ex.AsStatus()
		Use %Log $$$REPORT(0,"ERROR: EnsUpdate failed: "_$system.Status.GetErrorText(tSC))
	}
	Set $Namespace=tOldNamespace
	Quit tSC
}

/// Setting pEditGlobals to 0 allows for suppressing globals edits and global collation checks while mapping globals. This may lead to potential global mismatch errors.
/// Setting pEditGlobals to 1 (default) allows the creation of a global directory entry for each local global to be mapped, with same collation as ENSLIB (IRIS standard).
ClassMethod map2enslib(pTargetNS As %String = {$NAMESPACE}, pVerbose As %Boolean = 0, pEditGlobals As %Boolean = 1) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Quit:'..validateNamespace(.pTargetNS,0,.tSC) tSC
	
	; Change namespace to "%SYS"
	If $NAMESPACE'="%SYS" {
		New $NAMESPACE
		Set $NAMESPACE = "%SYS"
	}
	;
	Set $ZT="Trap",tSC=$$$OK
	If '$Data(%Log) New %Log Set %Log=$IO
	Do {	
		Set tSC = ..createMappings(pTargetNS,,pVerbose,,pEditGlobals)
		Quit:$$$ISERR(tSC)
	} While(0)
Exit
	kill tCfg
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Use %Log $$$REPORT(0,"ERROR: EnsUpdate failed: "_$system.Status.GetErrorText(tSC))
	Goto Exit
}

ClassMethod unmap2enslib(pTargetNS As %String = {$NAMESPACE}, pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Quit:'..validateNamespace(.pTargetNS,0,.tSC) tSC
	
	; Change namespace to "%SYS"
	If $NAMESPACE'="%SYS" {
		New $NAMESPACE
		Set $NAMESPACE = "%SYS"
	}
	;
	Set $ZT="Trap",tSC=$$$OK
	If '$Data(%Log) New %Log Set %Log=$IO
	Do {	
		
		$$$REPORT(4,"* Mappings:")
		Set tSC = ..deleteMappings(pTargetNS,,pVerbose)
		Quit:$$$ISERR(tSC)
		
		// Done!
		$$$REPORT(4,"* Complete!")
		
	} While(0)
Exit
	kill tCfg
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Use %Log $$$REPORT(0,"ERROR: EnsUpdate failed: "_$system.Status.GetErrorText(tSC))
	Goto Exit
}

/// Private helper method to create Interoperability mappings for a particular namespace
/// See ClassMethod map2enslib() for pEditGlobals description. 
ClassMethod createMappings(pTargetNS As %String, pEnsLib As %String = {..#ENSLIB}, pVerbose As %Boolean = 0, ByRef pIsPrimary, pEditGlobals As %Boolean = 1) As %Status [ Internal ]
{
	s tSC = ..mapCategory2enslib(pTargetNS, "Class", pVerbose,,,pEnsLib)
	Quit:$$$ISERR(tSC) tSC
	s tSC = ..mapCategory2enslib(pTargetNS, "Routine", pVerbose,,,pEnsLib)
	Quit:$$$ISERR(tSC) tSC
	s tSC = ..mapCategory2enslib(pTargetNS, "Global", pVerbose, .pIsPrimary, pEditGlobals, pEnsLib)
	Quit:$$$ISERR(tSC) tSC
	If ##class(Config.Databases).Exists("IRISMETRICS") {
		s tSC = ..mapCategory2enslib(pTargetNS, "Global", pVerbose, .pIsPrimary, pEditGlobals, "IRISMETRICS")
	}
	Quit tSC
}

/// Method to replace map2enslib for use cases where only classes in a namespace need to be mapped to Enslib
ClassMethod mapClasses2enslib(pTargetNS As %String = {$NAMESPACE}, pVerbose As %Boolean = 0) As %Status
{
	Quit ..mapCategory2enslib(pTargetNS, "Class", pVerbose)
}

/// Method to replace map2enslib for use cases where only routine in a namespace need to be mapped to Enslib
ClassMethod mapRoutine2enslib(pTargetNS As %String = {$NAMESPACE}, pVerbose As %Boolean = 0) As %Status
{
	Quit ..mapCategory2enslib(pTargetNS, "Routine", pVerbose)
}

/// Method to replace map2enslib for use cases where only globals in a namespace need to be mapped to Enslib
/// See ClassMethod map2enslib() for pEditGlobals description. 
ClassMethod mapGlobals2enslib(pTargetNS As %String = {$NAMESPACE}, pVerbose As %Boolean = 0, pEditGlobals As %Boolean = 1, ByRef pIsPrimary) As %Status
{
	Quit ..mapCategory2enslib(pTargetNS, "Global", pVerbose, .pIsPrimary, pEditGlobals)
}

/// Internal method to create either one of Class, Global or Routine mappings to Enslib namespace
/// pTargetCategory can either be "Class", "Routine" or "Global"
/// See ClassMethod map2enslib() for pEditGlobals description. 
ClassMethod mapCategory2enslib(pTargetNS As %String = {$NAMESPACE}, pTargetCategory As %String, pVerbose As %Boolean = 0, ByRef pIsPrimary, pEditGlobals As %Boolean = 1, pEnsLib As %String = {..#ENSLIB}) As %Status [ Internal ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Set pTargetCategory = $ZCVT($G(pTargetCategory),"U")
	Quit:'..validateNamespace(.pTargetNS,0,.tSC) tSC
	If $NAMESPACE'="%SYS" {
		New $NAMESPACE
		Set $NAMESPACE = "%SYS"
	}
	Try {
		Set tSC=$$$OK
		If '$Data(%Log) New %Log Set %Log=$IO
		If pTargetCategory = "CLASS" {Set tSC = ..createClassMappings(pTargetNS, pEnsLib,pVerbose)}
		ElseIf pTargetCategory = "ROUTINE" {Set tSC = ..createRoutineMappings(pTargetNS, pEnsLib,pVerbose)}
		Else {Set tSC = ..createGlobalMappings(pTargetNS, pEnsLib,pVerbose, .pIsPrimary, pEditGlobals)}
		Quit:$$$ISERR(tSC)
		$$$REPORT(4,"* "_pTargetCategory_" Mappings Complete!")
	} Catch {
		Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
		Use %Log $$$REPORT(0,"ERROR: EnsUpdate failed: "_$system.Status.GetErrorText(tSC))
	}
	Quit tSC
}

/// Internal helper method to create Interoperability mappings for classes for a particular namespace
ClassMethod createClassMappings(pTargetNS As %String, pEnsLib As %String = {..#ENSLIB}, pVerbose As %Boolean = 0) As %Status [ Internal ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	#dim tSC As %Status = $$$OK
	#dim tPackage As %String
	
	; Note: For all mappings below, changes are made with only the $$$CPFSave flag.
	; This method must both write the changes to the CPF and activate the changes for them to take effect.
	Set pTargetNS = $zcvt(pTargetNS,"U")
	; Add class mappings ...
	$$$REPORT(6,"- Class Mappings:")
	
	For tPackage = "Ens", "EnsLib", "EnsPortal", "CSPX.Dashboard" {
		
		If '##Class(Config.MapPackages).Exists(pTargetNS,tPackage) {
			$$$REPORT(8,"+ Adding class mapping "_tPackage_" -> "_pEnsLib)
			k p
			s p("Database")=pEnsLib
			s tSC=##Class(Config.MapPackages).Create(pTargetNS,tPackage,.p,,$$$CPFSave)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to create class mapping "_tPackage_": "_$system.Status.GetErrorText(tSC))
				Continue
			}
		} Else {
			$$$REPORT(8,"+ Class mapping "_tPackage_" already exists ... skipping")
		}
	}

	Set tSC=..UpdateAndReloadCPF(pVerbose,pTargetNS)
 	Quit tSC
}

/// Internal helper method to create Interoperability mappings for routine for a particular namespace
ClassMethod createRoutineMappings(pTargetNS As %String, pEnsLib As %String = {..#ENSLIB}, pVerbose As %Boolean = 0) As %Status [ Internal ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	#dim tSC As %Status = $$$OK
	#dim tRtn As %String
	
	; Note: For all mappings below, changes are made with only the $$$CPFSave flag.
	; This method must both write the changes to the CPF and activate the changes for them to take effect.
	Set pTargetNS = $zcvt(pTargetNS,"U")
	; Add a routine mapping for Ens*.
	$$$REPORT(6,"- Routine Mappings:")
	For tRtn = "Ens*" {
		$$$REPORT(8,"+ Adding routine mapping "_tRtn_" -> "_pEnsLib)
		If '##Class(Config.MapRoutines).Exists(pTargetNS,tRtn) {
			k p
			s p("Database")=pEnsLib
			Set tSC = ##Class(Config.MapRoutines).Create(pTargetNS,tRtn,.p,,$$$CPFSave)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to create routine mapping for "_tRtn_" -> "_pEnsLib_": "_$system.Status.GetErrorText(tSC))
				Continue
			}
		} Else {
			$$$REPORT(8,"+ Routine mapping "_tRtn_" already exists ... skipping")
		}
	}

	Set tSC=..UpdateAndReloadCPF(pVerbose,pTargetNS)
 	Quit tSC
}

/// Internal helper method to create Interoperability mappings for globals for a particular namespace
/// See ClassMethod map2enslib() for pEditGlobals description. 
ClassMethod createGlobalMappings(pTargetNS As %String, pDatabase As %String = {..#ENSLIB}, pVerbose As %Boolean = 0, ByRef pIsPrimary, pEditGlobals As %Boolean = 1) As %Status [ Internal ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	#dim tSC As %Status = $$$OK
	#dim tGlbName,tGblMap As %String
	; Note: For all mappings below, changes are made with only the $$$CPFSave flag.
	; This method must both write the changes to the CPF and activate the changes for them to take effect.
	Set pTargetNS = $zcvt(pTargetNS,"U")

	; Add/fix global mappings
	$$$REPORT(6,"- Global Mappings:")
	Kill tGblMap, tGlbName
	// Get array of all global mappings to be created
	Do ..getMappedGlobals(.tGblMap, pDatabase, pTargetNS)

	/*
		Get array of all global *names* to be mapped
		Each global could reside in a different db so we cannot just check default Globals db.
		For each global find db where it resides.
		For each db find if remote.
		For each db that is remote skip creating or changing collation.
	*/
	#dim tLocalGlobals As %String
	#dim tGblDestDir As %String
	#dim tGblDestSystem As %String
	#dim tGblDestNameList As %String
	#dim tDBName As %String
	#dim tSCDBInfo As %Status = $$$OK

	#dim tGlobalDatabases As %String
	#dim tLocalGlobalDirectories As %String
	
	Set tGblMap = ""
	For {
		Set tGblMap = $O(tGblMap(tGblMap))
		Quit:tGblMap=""
		Set tGlbName = $P(tGblMap,":",1)
		If (tGlbName'="") && '$D(tGlbName(tGlbName))#2 {
			#; Only want to do this once per Global Name
			Set tGlbName(tGlbName) = ""
			
			#; Check where the global is supposed to default to. Split off System name.
			Set tGblDestDir = ##class(%SYS.Namespace).GetGlobalDest(pTargetNS,tGlbName)
			Set tGblDestSystem = $P(tGblDestDir,"^",1)
			Set tGblDestDir = $P(tGblDestDir,"^",2)
			
			#; Find Database name
			Set tSCDBInfo = ##class(Config.Databases).DatabasesByDirectory(tGblDestSystem,tGblDestDir,.tGblDestNameList)
			If $$$ISERR(tSCDBInfo) {
				$$$REPORT(8,"+ Can't create routine directory entries for Global : '"_tGlbName_"'"_$system.Status.GetErrorText(tSC))
				Continue
			}
			Set tDBName =$LG(tGblDestNameList)
			If tGblDestSystem="" {
				Set tLocalGlobals(tGlbName)=""
			} Else {
				$$$REPORT(8,"Database server '"_tGblDestSystem_"' not local, can't set global directory entry for "_tGlbName)
			}
			
			#; Used when creating or modifying local root globals
			Set tLocalGlobalDirectories(tGlbName)=tGblDestDir
						
			#; Used later when doing the mapping for the root global if not already mapped.
			Set tGlobalDatabases(tGlbName)=tDBName
			
		}
	}
	// Create a global directory entry for each local global to be mapped, with same collation as ENSLIB (IRIS standard)
	// Note 1: This is only possible for local databases
	// Note 2: We do not do if this is a mirrored NS and not primary
	If pEditGlobals
	{ 
		If '$D(pIsPrimary) Set tSC = ..populateIsPrimary(.pIsPrimary)
		If (pIsPrimary||'$data(pIsPrimary("MirrorNS",pTargetNS))) {
			Try {			
				#dim tDir As %String
				#dim tGlobal As %String
				#dim tNSP As %String
				#dim tDataMoved As %Integer

				#; Only handle local globals
				#; Also do not handle system dbs since these can be included if re-run after mappings created
				#dim tSkipModifyDirectories As %String
				#dim tDB, tSystemDBName
				For tSystemDBName = ..#ENSLIB, ..#HSLIB {
					If ##class(Config.Databases).Exists(tSystemDBName, .tDB) {
						If tDB.Directory'="" Set tSkipModifyDirectories($zcvt(tDB.Directory,"l"))=""
						Kill tDB
					} Else {
						#; might not contain HSLIB for example
						Kill %objlasterror
					}
				}
				Kill tSystemDBName

				Set tGlbName = ""
				For {
					Set tGlbName = $O(tLocalGlobals(tGlbName))
					Quit:tGlbName=""
					Continue:'$zname(tGlbName,3)
					
					Set tDir = tLocalGlobalDirectories(tGlbName)
					If (tDir="") || $Data(tSkipModifyDirectories($zcvt(tDir,"l")))#2 {
						Continue
					}
					
					If $$$ISERR(..getDBRWFlag(tDir,.tDirIsRW)) || 'tDirIsRW {
						$$$REPORT(8,"+ Skipping Creating or checking/fixing global directory settings for global ^"_tGlbName_" in Read Only directory "_tDir)
						Continue
					}
					Set tGlobal = ##Class(%GlobalEdit).Open(tGlbName, tDir, , , .tSC)
					If $$$ISOK(tSC) && $IsObject(tGlobal) {
						// Existing global
						$$$REPORT(8,"+ Checking/fixing global directory settings for existing global ^"_tGlbName_" in directory "_tDir)
						If tGlobal.IsKeep'=1 {
							$$$REPORT(10,"+ Modifying property IsKeep = [1]")
							Set tGlobal.IsKeep = 1
							Set tSC = tGlobal.%Save()
							If $$$ISERR(tSC) {
								$$$REPORT(12,"Error when saving modified global entry: "_$system.Status.GetErrorText(tSC))
							}
						}
						If tGlobal.Collation'=5 {
							// If there is global data (unmapped) in the database then save a copy to a temp location so it can be restored later
							Set tNSP =  "^^"_tDir, tDataMoved = 0
							Set tSC = ..moveToFromInstallTemp("To",tNSP,tGlbName,.tDataMoved)
							If $$$ISERR(tSC) {
								$$$REPORT(12,"Error merging global prior to collation change: "_$system.Status.GetErrorText(tSC))
							}
							$$$REPORT(10,"+ Modifying property Collation = [5] (IRIS standard)")
							Set tGlobal.Collation = 5
							Set tSC = tGlobal.%Save()
							If $$$ISERR(tSC) {
								$$$REPORT(12,"Error when saving modified global entry: "_$system.Status.GetErrorText(tSC))
							}
							If tDataMoved {
								$$$REPORT(10,"+ Restoring previously existing (unmapped) local global data")
								Set tSC = ..moveToFromInstallTemp("From",tNSP,tGlbName)
								If $$$ISERR(tSC) {
									$$$REPORT(12,"Error merging global back after collation change: "_$system.Status.GetErrorText(tSC))
								}
							}
						}
					}
					Else {
						// New global
						Kill %objlasterror
						Set tGlobal = ##Class(%GlobalEdit).%New(tDir)
						If $IsObject(tGlobal) {
							$$$REPORT(8,"+ Creating new global directory entry for ^"_tGlbName)
							Set tGlobal.Name = tGlbName
							Set tGlobal.IsKeep = 1
							Set tGlobal.Collation = 5
							Set tSC = tGlobal.%Save()
							If $$$ISERR(tSC) {
								$$$REPORT(10,"Error when saving global entry: "_$system.Status.GetErrorText(tSC))
							}
						}
						Else {
							Set tSC = $G(%objlasterror, $$$ERROR($$$GeneralError,"Undetermined error when creating new instance of %GlobalEdit"))
							$$$REPORT(8,"+ Error when creating new global directory entry for ^"_tGlbName_": "_$system.Status.GetErrorText(tSC))
						}
					}
				}
			}
			Catch {
				Set tSC = $$$ERROR($$$ObjectScriptError, $ZE)
				$$$REPORT(8,"+ Error while creating global directory entries: "_$system.Status.GetErrorText(tSC))
			}
		} Else {
			$$$REPORT(8,"* Skipping creating global directory entries for each global to be mapped, as namespace "_pTargetNS_" contains mirrored data and is not primary.")
		}
	}
	// Now add the global mappings
	Set tGblMap = ""
	#dim tSubscript, tGbl,p As %String
	For {
		Set tGblMap = $O(tGblMap(tGblMap))
		Quit:tGblMap=""
		
		Set tSubscript = $P(tGblMap,":",2,$L(tGblMap,":"))
		Set tGbl = $P(tGblMap,":")
		$$$REPORT(8,"+ Adding global mapping ^"_tGbl_tSubscript_" -> "_pDatabase)
		
		If '##Class(Config.MapGlobals).Exists(pTargetNS,tGbl_tSubscript) {
			/*	Need to create root global mappings if not exist
				in case different Database (for example, the routine database)
				as the SLM creation will set to default globals database
				if not already set.
				If tSubscript is empty then don't want to do double root create.
			*/	
			If (tSubscript'=""),$D(tGlobalDatabases(tGbl),tDBName)#2 {
				If '##Class(Config.MapGlobals).Exists(pTargetNS,tGbl) {
					k p
					s p("Database")=tDBName
					Set tSC = ##Class(Config.MapGlobals).Create(pTargetNS,tGbl,.p,,$$$CPFSave)
					If $$$ISERR(tSC) {
						$$$REPORT(0,"ERROR: Failed to recreate system global mapping "_tGbl_": "_$system.Status.GetErrorText(tSC))
						Continue
					}
				}
				#; Clean up since no need to run MapGlobals Exists check again for root global
				Kill tGlobalDatabases(tGbl)
			}
			
			#; Make SLM to database
			k p
			s p("Database")=pDatabase
			Set tSC = ##Class(Config.MapGlobals).Create(pTargetNS,tGbl_tSubscript,.p,,$$$CPFSave)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to create global mapping "_tGbl_": "_$system.Status.GetErrorText(tSC))
				Continue
			}
		} Else {
			$$$REPORT(8,"+ Global mapping "_tGbl_" already exists ... skipping")
		}
	}

	Set tSC=..UpdateAndReloadCPF(pVerbose,pTargetNS)
	
	If 'pEditGlobals $$$REPORT(8,$CHAR(10)_"NOTE: Skipped creating or checking/fixing global directory settings as pEditGlobals is set to 0. Collation checks not carried out!"_$CHAR(10))
 	Quit tSC
}

/// Private helper method to create Interoperability mappings for a particular namespace
ClassMethod deleteMappings(pTargetNS As %String, pEnsLib As %String = {..#ENSLIB}, pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set tSC = $$$OK
	
	; Remove global mappings
	$$$REPORT(6,"- Global:")
	
	// Now, enumerate the mappings for this namespace
	s Rset=##Class(%Library.ResultSet).%New("Config.MapGlobals:List")
	s Status=Rset.Execute(pTargetNS)
	While Rset.Next() {
		s Name=Rset.Get("Name")
		s Database=Rset.Get("Database")
		i Database'=pEnsLib continue
		s tList(Name)=""
	}
		
	s Index=""
	f  {
		s Index=$o(tList(Index)) q:Index=""
		$$$REPORT(8,"+ Removing global mapping ^"_Index_" -> "_pEnsLib)
		Set tSC = ##Class(Config.MapGlobals).Delete(pTargetNS,Index,,$$$CPFSave)
		If $$$ISERR(tSC) {
			$$$REPORT(0,"ERROR: Failed to remove global mapping "_Name_": "_$system.Status.GetErrorText(tSC))
			Continue
		}
	}
	Set tSC=..UpdateAndReloadCPF(pVerbose,pTargetNS)
  	Quit tSC
}

ClassMethod createPortal(pTargetNS As %String, pVerbose As %Boolean = 0, ByRef pPortalSuffix As %String = "", ByRef pPortalPrefix As %String = "", pGrant As %String = "", pCookiePath As %String = "", pAuthMethods As %String = "", pEnslib As %String = {..#ENSLIB}, ByRef pIsPrimary As %Boolean = 1, pGroupById As %String = {$$$IscMgtPortalId}) As %Status [ Internal ]
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		// Validate the namespace
		Quit:'..validateNamespace(.pTargetNS,0,.tSC)
		
		If $E(pPortalSuffix,1,5)'="/csp/" {
			If pPortalSuffix'="" {
				Set:$E(pPortalSuffix,1)'="/" pPortalSuffix="/"_pPortalSuffix
			}
			
			Set:$E(pPortalPrefix,1)'="/" pPortalPrefix="/csp/"_pPortalPrefix
			Set:$E(pPortalPrefix,$L(pPortalPrefix))'="/" pPortalPrefix=pPortalPrefix_"/"

	 		// Create a portal in the specified namespace, and copy in the portal from /csp/enslib
			Set tPortal = pPortalPrefix_$tr($ZCVT(pTargetNS,"L"),"%")_pPortalSuffix
		} Else {
			// Entire URL was specified
			Set tPortal = pPortalSuffix
		}
		
		Set tPortalNS=pTargetNS
		Set tPortalDir = $System.Util.DataDirectory()
		For i=2:1:$L(tPortal,"/") {
			Set tPortalDir = ##class(%File).SubDirectoryName(tPortalDir,$P(tPortal,"/",i))
		}
		
 		$$$REPORT(6,"- Configuring portal: "_tPortal_" ["_tPortalNS_"] using "_tPortalDir)
 		#dim tAppDescription = ..namespaceProductionType()_" Management Portal"
		Set tSC = ..createPortalApp(tPortal,tPortalNS,tPortalDir,tAppDescription,"%Ens_Portal",1,,pGrant,pCookiePath,pAuthMethods,,pVerbose,pGroupById)
		Quit:$$$ISERR(tSC)
		
		Set tPortalDir = ##class(%Library.File).NormalizeDirectory(tPortalDir)
		If $extract(tPortal,*)'="/" Set tPortal = tPortal _ "/"
		$$$REPORT(6,"- Removing legacy CSP pages and files from directory '"_tPortalDir_"'")
		Set tSC = ..RemoveLegacyPortal(pTargetNS,tPortalDir,tPortal,1,,pVerbose)
	} While(0)
Exit
	// Report any errors in verbose mode
	If pVerbose,$$$ISERR(tSC) {
		$$$REPORT(0,"ERROR: Failed to create portal: "_$system.Status.GetErrorText(tSC))
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
	
compilePortal(pPortal,pPortalNS,pVerbose=0)
	Set tSC=$$$OK,$ZT="compileTrap"
	If $NAMESPACE'=pPortalNS {
		New $NAMESPACE
		Set $NAMESPACE = pPortalNS
	}
	Set tFlags = "c"_$S(pVerbose:"+",1:"-")_"d"
	Write:pVerbose !,?8,"+ Compiling "_pPortal_" in ",$namespace
	For tDir=pPortal {
		Set tSC = $$LoadPageDir^%apiCSP(tDir,tFlags)
		Do:pVerbose $system.OBJ.DisplayError(tSC)
	}
compileExit
	Quit tSC
compileTrap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto compileExit
}

/// Helper to create a CSP portal application
ClassMethod createPortalApp(pPortal As %String, pNS As %String, pPortalDir As %String, pDescription As %String, pResource As %String = "", pRecursive As %Boolean = 1, pLoginPage As %String = "", pGrant As %String = "", pCookiePath As %String = "", pAuthMethods As %String = "", pLockCSPName As %Boolean = 1, pVerbose As %Boolean = 0, pGroupById As %String = "", pCspZenEnabled As %Boolean = 1, pInboundWebServicesEnabled As %Boolean = 1, pTwoFactorEnabled As %Boolean = 0, pIsNameSpaceDefault As %Boolean = 0, pPermittedClasses As %String = "") As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

#ifndef REPORTPROP
#define REPORTPROP(%l,%x,%y) Write:pVerbose !,?%l,%x,$J("",20-$L(%x))," = ["_%y,"]"
#endif

	If ($G(pPortal)="") || ($G(pNS)="") || ($G(pPortalDir)="") {
		Set msg = "- ERROR when creating Portal application: Application name, namespace and directory must not be null"
		Set tSC = $$$ERROR($$$GeneralError,msg)
		$$$REPORT(6,msg)
		Quit tSC
	}

	Try {
	 	If '##class(%File).DirectoryExists(pPortalDir) {
		 	$$$REPORT(6,"- Creating directory: "_pPortalDir)
			Do ##class(%File).CreateDirectory(pPortalDir)
	 	}
 
	 	// Ensure the cookie path is reasonable and ends in a /
	 	Set:$G(pCookiePath)="" pCookiePath = pPortal
	 	Set:$E(pCookiePath,$L(pCookiePath))'="/" pCookiePath = pCookiePath_"/"

		// Check if we are creating or udating the Portal CSP application 
	 	Set Exists = ##class(Security.Applications).Exists(pPortal, .tApp, .tSC)
 
	 	If Exists {
		 	$$$REPORT(6,"- Updating CSP Application: "_pPortal)
		 	If tApp.Resource = "%Admin_Manage" {
				Set tApp.Resource = pResource
				$$$REPORTPROP(10,"Resource", pResource)
			}
	 	}
	 	Else {
			$$$REPORT(6,"- Creating CSP Application: "_pPortal)
			Set tApp = ##class(Security.Applications).%New()
			 // Use pAuthMethods if a value is passed, otherwise use default security (HCR152)
			If pAuthMethods {
				Set CSPAppSec = +pAuthMethods
			}
			Else {
				Set CSPAppSec = ..DetermineCSPAppSec()
			}
			// For HealthShare, add delegated authentication
			IF ..IsHealthShareInstalled()&&'$zb(CSPAppSec,$$$AutheDelegated,1) {
				Set tSC=##Class(Security.System).Get(,.tProp) Quit:$$$ISERR(tSC)
				If $zb(+tProp("AutheEnabled"),$$$AutheDelegated,1) { Set CSPAppSec=CSPAppSec+$$$AutheDelegated}
			}
			Set tApp.Name = pPortal $$$REPORTPROP(10,"Name",pPortal)
			Set tApp.AutheEnabled = CSPAppSec $$$REPORTPROP(10,"AutheEnabled",CSPAppSec)
			Set tApp.Enabled = 1 $$$REPORTPROP(10,"Enabled",1)
			Set tApp.Description = pDescription $$$REPORTPROP(10,"Description",pDescription)
			Set tApp.Resource = pResource $$$REPORTPROP(10,"Resource",pResource)
			Set tApp.AutoCompile = 0 $$$REPORTPROP(10,"AutoCompile",0)
			Set tApp.Timeout= 900 $$$REPORTPROP(10,"Timeout",900)
			Set tApp.Path = pPortalDir $$$REPORTPROP(10,"Path",pPortalDir)
			Set tApp.Recurse = pRecursive $$$REPORTPROP(10,"Recurse",pRecursive)
			Set tApp.LoginPage = pLoginPage $$$REPORTPROP(10,"LoginPage",pLoginPage)
			Set tApp.InbndWebServicesEnabled = pInboundWebServicesEnabled $$$REPORTPROP(10,"InbndWebServicesEnabled",pInboundWebServicesEnabled)
			Set tApp.TwoFactorEnabled = pTwoFactorEnabled $$$REPORTPROP(10,"TwoFactorEnabled",pTwoFactorEnabled)
			Set tApp.IsNameSpaceDefault = pIsNameSpaceDefault $$$REPORTPROP(10,"IsNameSpaceDefault",pIsNameSpaceDefault)
			Set tApp.PermittedClasses = pPermittedClasses $$$REPORTPROP(10,"PermittedClasses",pPermittedClasses)
			If pGrant'="" {
				Set tGrant=""
				For i = 1:1:$L(pGrant,",") {
					Set r = $P(pGrant,",",i)
					Set:r'="" tGrant=tGrant_":"_r
				}
				//tGrant must be of format :grant1:grant2 etc
				Do:tGrant'="" tApp.MatchRoles.Insert(tGrant)
			 }
			$$$REPORTPROP(10,"MatchRoles",pGrant)
		}

		// Set properties that are required for the Interoperability Portal to work properly
		Set tApp.Type = $$$AppTypeCSP $$$REPORTPROP(10,"Type",$$$AppTypeCSP)
		Set tApp.CookiePath = pCookiePath $$$REPORTPROP(10,"CookiePath",pCookiePath)
		Set tApp.LockCSPName = pLockCSPName $$$REPORTPROP(10,"LockCSPName",pLockCSPName)
		Set tApp.NameSpace = pNS $$$REPORTPROP(10,"NameSpace",pNS)
		Set tApp.CSPZENEnabled = pCspZenEnabled $$$REPORTPROP(10,"CSPZENEnabled",pCspZenEnabled)
		Set tDoGroupById = 1
		// Only change GroupById once after upgrading
		If (pGroupById = $$$IscMgtPortalId) && (tApp.GroupById = "") && ..IsEnsembleInstalled() {
			If (Exists) && $DATA(^%SYS("Ensemble","CSPApp",$zcvt(pNS,"U"),"GroupById",pPortal)) {
				Set tDoGroupById = 0
			}
			Else {
				Set ^%SYS("Ensemble","CSPApp",$zcvt(pNS,"U"),"GroupById",pPortal) = ""
			}
		}
		If tDoGroupById Set tApp.GroupById = pGroupById $$$REPORTPROP(10,"GroupById",pGroupById)
		Set tApp.ServeFiles = 2 $$$REPORTPROP(10,"ServeFiles",2) // Always and Cached
		Set tApp.UseCookies = 2 $$$REPORTPROP(10,"UseCookies",2) // Set UseCookies to Always
		
		// Save Portal's CSP application
		Set tSC = tApp.%Save()
	}
	Catch {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	}
	
	Quit tSC
}

/// Helper method to modify interop editors app
ClassMethod modifyInteropEditorsAPIApp(pNS As %String, pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set tSC = $$$OK
	Try {
		If '##class(Security.Applications).Exists("/api/interop-editors", .tApp, .tSC) {
		$$$REPORT(6,"- Interop Editors Application does not exist")
		}
		Quit:$$$ISERR(tSC)

		If 'tApp.MatchRoles.Find(":%EnsRole_InteropEditorsAPI") {
			$$$REPORT(6,"- Giving Interop Editors application %EnsRole_InteropEditorsAPI role")
			Set tApp.MatchRoles = tApp.MatchRoles.Insert(":%EnsRole_InteropEditorsAPI")
			Set tSC = tApp.%Save()
		} Else {
			$$$REPORT(6,"- Interop Editors application already has %EnsRole_InteropEditorsAPI role")
		}
	} Catch {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	}
	Quit tSC
}

/// Helper method to identify which authentication methods we will enable for the CSP app
ClassMethod DetermineCSPAppSec() As %Integer [ Internal, Private ]
{
	Set CSPAppSec = 0
	
	Try {
		// Default security for CSP applications based on initial security type is stored in ^%SYS("CSPAppSec")
		// for Ensemble and Cache.
	
		If $D(^%SYS("Ensemble","CSPAppSec")) {
			// Move CSPAppSec subscript one level up in case it's still in its old location. (HCR152)
			Merge ^%SYS("CSPAppSec") = ^%SYS("Ensemble","CSPAppSec")
			Kill ^%SYS("Ensemble","CSPAppSec")
		}
	
		Set CSPAppSec = +$G(^%SYS("CSPAppSec"))
		If 'CSPAppSec {
			// Determine and save default settings, depending on initial security type
			Try {
				Set s = ##class(Security.System).GetInstallationInfo(.Info)
				Set Type = $G(Info("InitialSecuritySettings"))
				If Type'="" {
					// This information is only available at installation time!
					If Type="None" {
						Set CSPAppSec = $$$AutheUnauthenticated
					}
					ElseIf Type="Normal" {
						Set CSPAppSec = $$$AutheCache
					}
					Else {
						Set CSPAppSec = $$$AutheLDAP+$$$AutheCache+$$$AutheK5API
					}
					If CSPAppSec Set ^%SYS("CSPAppSec") = CSPAppSec
				}
			}
			Catch {
			}
		}
		If 'CSPAppSec {
			// Couldn't identify, will use our general default
			Set CSPAppSec = ..#DEFAULTCSPAUTHMETHODS
		}
	}
	Catch {
	}
	
	Quit CSPAppSec
}

ClassMethod RemoveLegacyPortal(pTargetNS As %String = "", pPortalDir As %String = "", pPortalApp As %String = "", pFiles As %Boolean = 1, pClasses As %Boolean = 0, pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	If (pTargetNS = "") || (pPortalDir = "") || (pPortalApp = "") || ('##class(%Library.File).DirectoryExists(pPortalDir)) {
		Quit $$$OK
	}
	If '##class(%SYS.Namespace).Exists(pTargetNS) {
		Quit $$$ERROR($$$NamespaceDoesNotExist,pTargetNS)
	}
	Set tSC = $$$OK
	New $namespace
	Set tInitNS = $namespace
	Try {
		Set $namespace = "%SYS"
		// Actively remove CSPX package mapping
		If ##class(Config.MapPackages).Exists(pTargetNS,"CSPX",.tCSPXMap) {
			If $IsObject($get(tCSPXMap)) && (tCSPXMap.Database = ..#ENSLIB) {
				$$$REPORT(6,"- Removing CSPX package mapping for namespace '"_pTargetNS_"'")
				Set tSC = ##class(Config.MapPackages).Delete(pTargetNS,"CSPX")
				If $$$ISERR(tSC) Quit
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set $namespace = tInitNS
	If $$$ISERR(tSC) Quit tSC
	
	Set tTargetApp = ..DetermineMgmtURLForNamespace(pTargetNS,0)
	If tTargetApp = "" {
		// We don't know about this application, so we shouldn't remove any class in it!
		Quit $$$OK
	}
		
	Set tExpectedPortal = (tTargetApp = pPortalApp)
	If ('tExpectedPortal) && ..IsHealthShareNamespace(pTargetNS) {
		// check for ensemble/ application
		Set tExpectedPortal = ((tTargetApp _ $select($extract(tTargetApp,*) = "/":  "", 1: "/") _ "ensemble/")  = pPortalApp)
	}
	If 'tExpectedPortal {
		$$$REPORT(6,"WARNING: '"_pPortalApp_"' is not the expected Interoperability portal for namespace '"_pTargetNS_"'. Not removing legacy CSP files.")
		Quit $$$OK
	}
	
	Set tSC = $$$OK
	Set tEnsLib = ..GetENSLIB(1)
	Set tMerged = 0
	Try {
		Merge tPageList = ^|tEnsLib|Ens.LegacyPortal("Files")
		Set tMerged = 1
	}
	Catch ex {
		If ex.Name '[ "NAMESPACE" {
			Set tSC = ex.AsStatus()
		}
	}
	If $$$ISERR(tSC) Quit tSC
	If 'tMerged Quit $$$OK
	
	Set tFileSC = $$$OK
	If pFiles {
		For tType = "CSP","OTHER" {
			Set tSub = ""
			For {
				Set tSub = $order(tPageList(tType,tSub))
				Quit:(tSub = "")
				// We only go one level deep
				If $data(tPageList(tType,tSub))\10 {
					Set tFullDir = ##class(%Library.File).SubDirectoryName(pPortalDir,tSub,1)
					If ##class(%Library.File).DirectoryExists(tFullDir) {
						Set tFileKey = ""
						For {
							Set tFileKey = $order(tPageList(tType,tSub,tFileKey))
							Quit:(tFileKey = "")
							Set tFilename = ##class(%Library.File).NormalizeFilename(tFileKey, tFullDir)
							If ##class(%Library.File).Exists(tFilename) {
								Set tResult = ##class(%Library.File).Delete(tFilename)
								If 'tResult {
									Set tSC1 = $$$ERROR($$$FileCanNotDelete,tFilename)
									Set tFileSC = $$$ADDSC(tFileSC,tSC1)
								}
							}
						}
						Set tRS = ##class(%Library.ResultSet).%New("%Library.File:FileSet")
						If $$$ISOK(tRS.Execute(tFullDir)) && 'tRS.Next() && '##class(%Library.File).RemoveDirectory(tFullDir) {
							Set tSC1 = $$$ERROR($$$FileCanNotDelete,tFullDir)
							Set tFileSC = $$$ADDSC(tFileSC,tSC1)
						}
					}
				}
				Else {
					Set tFilename = ##class(%Library.File).NormalizeFilename(tSub, pPortalDir)
					If ##class(%Library.File).Exists(tFilename) {
						Set tResult = ##class(%Library.File).Delete(tFilename)
						If 'tResult {
							Set tSC1 = $$$ERROR($$$FileCanNotDelete,tFilename)
							Set tFileSC = $$$ADDSC(tFileSC,tSC1)
						}
					}
				}
			}
		}
	}
	Set tClassSC = $$$OK
	If pClasses {
		Set tInitNS = $namespace
		Try {
			Set $namespace = pTargetNS
			Set tPage = ""
			For {
				Set tPage = $order(tPageList("CSP",tPage))
				Quit:(tPage = "")
				If $data(tPageList("CSP",tPage)) \ 10 {
					Set tPageKey = ""
					For {
						Set tPageKey = $order(tPageList("CSP",tPage,tPageKey))
						Quit:(tPageKey = "")
						Set tClass = $system.CSP.GetClassName(pPortalApp_tPage_"/"_tPageKey)
						If (tClass '= "") && ##class(%Dictionary.ClassDefinition).%ExistsId(tClass) {
							Set tSC1 = $system.OBJ.Delete(tClass)
							If $$$ISERR(tSC1) {
								Set tClassSC = $$$ADDSC(tClassSC,tSC1)
							}
						}
					}
				}
				Else {
					Set tClass = $system.CSP.GetClassName(tPage,pPortalApp)
					If (tClass '= "") && ##class(%Dictionary.ClassDefinition).%ExistsId(tClass) {
						Set tSC1 = $system.OBJ.Delete(tClass)
						If $$$ISERR(tSC1) {
							Set tClassSC = $$$ADDSC(tClassSC,tSC1)
						}
					}
				}
			}
		}
		Catch ex {
			Set tClassSC = ex.AsStatus()
		}
		If $namespace '= tInitNS {
			Set $namespace = tInitNS
		}
	}
	Quit $$$ADDSC(tClassSC,tFileSC)
}

ClassMethod setDBRWFlag(dir As %String, flag As %Integer, timeout As %Integer = -1) As %Status [ Internal, Private ]
{
	Set flag='flag, tSC = $$$OK
	#dim tWaited = 0
	#dim tExpandInterval = 2
	For  {
		Set db = ##class(SYS.Database).%OpenId(dir)
		If '$IsObject(db) Quit

		If 'db.Mounted {
			Set tSC = db.Mount()
			/* If fail to Mount then do not attempt retry unless expanding */
			If 'db.Expanding && ($$$ISERR(tSC) || 'db.Mounted) {
				Set db = ""
				Quit
			}
		}
		If db.Expanding {
			hang tExpandInterval
			Set db=""
			If timeout > 0 {
				Set tWaited = tWaited + tExpandInterval
				If tWaited >= timeout {
					Set tSC = $$$ERROR($$$GeneralError,"Timedout waiting for "_dir_" to finish expanding.")
					Quit
				}
			}
			Continue
		}
		Quit
	}
	If $IsObject(db) {
		/* If still expanding then do not attempt to change read only flag */
		If (db.ReadOnly '= flag) && 'db.Expanding {
			Set db.ReadOnly = flag
			Set tSC = db.%Save()
		}
	} ElseIf $$$ISOK(tSC) {
		Set tSC = $G(%objlasterror,($$$ERROR($$$GeneralError,"Error modifying ReadOnly flag for "_dir)))
	}
	Kill db
	Quit tSC
}

/// Create resource pResource if it does not exist already. <br>
/// Assign the resource to the database pDatabase. This call will attempt to mount the db RW if it is mounted read only. <br>
/// If pDatabase is empty string then do not try to update the db label with the resource.<br>
ClassMethod assignResourceToDB(pResource As %String, pDatabase As %String, pPublicPermissions As %String = "RW") As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim tDescription = "The "_$P(pResource,"%DB_",2)_" database"

	// If the resource already exists, and its description is in old format, convert the description directly in the global
	#dim tNode = $G(^SYS("Security","ResourcesD",$ZCVT(pResource,"l")))
	If $LV(tNode) && ($LG(tNode,2)[" Database resource") {
		Set $LI(tNode,2) = tDescription
		Set ^SYS("Security","ResourcesD",$ZCVT(pResource,"l")) = tNode
	}

	// Create a new resource if it doesn't exist already (as long as it's not %DB_%DEFAULT)
	#dim tObjResource
	If (pResource '= ..#DEFAULTDBRESOURCE), '##class(Security.Resources).Exists(pResource,.tObjResource,.tSC) || '$IsObject($G(tObjResource)) {
		Set tSC = ##class(Security.Resources).Create(pResource,tDescription,pPublicPermissions,3)
	}

	If $$$ISOK(tSC) && (pDatabase'="") {
		Set tDB = ##class(SYS.Database).%OpenId(pDatabase,0,.tSC)
		If $$$ISERR(tSC) Quit tSC
		If tDB.ResourceName = pResource {
			/// Already assigned in the case of docker container install / upgrade
			Quit tSC
		}
		// Update the database with the resource
		Set tSC = ..setDBattributes(pDatabase,$$$TOREADWRITE,pResource)
	}

	Quit tSC
}

/// Internal method to set DB Resource.
/// If the DB is expanding then the modification will
/// retry at increasing intervals up to 5 attempts over 
/// a total maximum wait of 10 seconds. <br>
/// mode can be the internal value for READWRITE or READONLY. 
/// Any other mode value not lead to an attempt to change the R/W flag.<br>
/// In order to modify the database the database does need to be mounted R/W <br>
/// The code will set the DB R/W flag first and then call the api to set the resource.<br>
/// For backwards compatibility the code does not reset the DB R/W flag after setting the
/// resource if the R/W flag is changed.<br>
ClassMethod setDBattributes(dir As %String, mode As %String, rnam As %String) [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#dim rc=$zu(49,dir)
		If rc<0 {
			Set tSC = $$$ERROR($$$DatabaseDoesNotExist,dir)
			Quit
		}
		Set:$G(rnam)="" rnam=$p(rc,",",25) Set:rnam="" rnam=..#DEFAULTDBRESOURCE

		// Check that the resource is valid, otherwise $ZU(1) gives a <FUNCTION> error
		If ((rnam[",")||(rnam[":")||(rnam["/"))||((rnam '= ..#DEFAULTDBRESOURCE) && ($EXTRACT(rnam,$FIND(rnam,"_"))="%")) {
			// Resource name cannot contain ,:/ nor can there be a % right after the _ unless it's %DB_%DEFAULT
			Set tSC = $$$ERROR($$$ResourceInvalidName,rnam)
			Quit
		}
		// First set the RW flag as previously
		#dim tReadWrite = $Case(mode,$$$TOREADWRITE:1,$$$TOREADONLY:0,:-1)
		If (tReadWrite'=-1) {
			// setDBRWFlag includes checking for expanding as well
			Set tSC = ..setDBRWFlag(dir,tReadWrite,10)
		}
		If $$$ISOK(tSC) {
			/*	Based on wait algorithm for expanding in Config.NLS.Locales::Install
				Different algorithm from setDBRWFlag since setDBRWFlag historically allowed infinite wait
				and this method only ever allowed one attempt.
			*/ 
			#dim maxAttempts = 5
			#dim wait
			For wait=1:1:maxAttempts {
				Set tSC = ##class(SYS.Database).ModifyDatabase(dir,,rnam)
				#; If database expanding and we are not on last attempt
				If ($$$ISERR(tSC) && ((","_$System.Status.GetErrorCodes(tSC)_",")[(","_$$$ERRORCODE($$$DatabaseExpanding)_","))&&(wait<maxAttempts)) {
					Hang wait
				} Else {
					Quit
				}
			}
		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

ClassMethod getDBRWFlag(dir As %String, ByRef flag As %Integer) As %Status [ Internal, Private ]
{
	Set flag=0,tSC = $$$OK
	Set db = ##class(SYS.Database).%OpenId(dir)
	If $IsObject(db) {
		// flag == 1 means r/w
		Set flag = 'db.ReadOnly
	} Else {
		Set tSC = %objlasterror
	}
	Kill db
	Quit tSC
}

ClassMethod getMappedGlobals(ByRef pGlobals, pDatabase As %String = {..#ENSLIB}, pTargetNS As %String = "") [ Internal, Private ]
{
	Kill pGlobals
	Set tIO = $IO
	Try {
	
		// We build the list of global subscripts to be mapped from the contents of ^IRIS.Msg
		// in the ENSLIB database.  Thus, it will dynamically adapt as new domains are added.
	
		If '##class(Config.Databases).Exists(pDatabase, .tDB) {
			Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$DatabaseDoesNotExist, pDatabase))
		}
		New $namespace
		Set $namespace = "^^"_tDB.Directory
	
		If pDatabase = "IRISMETRICS" {
			If pTargetNS = "%SYS" {
				#; Only set from the %SYS namespace
				Set pGlobals($$$InteropMetricsInterfaceGblRoot)=""
				Set pGlobals($$$InteropMetricsConsolidatedGblRoot)=""
				Set pGlobals($$$InteropMetricsSendGblRoot)=""
				Set pGlobals($$$InteropMetricsActivityGblRoot)=""
				Set pGlobals("%SYS:(""Interop"",""FeatureTracker"")")=""
				Set pGlobals("%SYS:(""InteropMetrics"")")=""
				Set pGlobals($$$InteropMetricsDBImpRoot)=""
			}
			#; Set directly from productions in whatever namespace they're in
			Set pGlobals($$$InteropMetricsMsgGblRoot)=""
		} Else {

			Set tItem=""
			For {
				Set tItem=$ORDER(^IRIS.Msg(tItem))
				Quit:tItem=""
			
				Set pGlobals("IRIS.Msg:("""_tItem_""")")=""
				Set pGlobals("IRIS.MsgNames:("""_tItem_""")")=""
			}

			// Also, we build the list of mappings for HL7 schemas from ENSLIB
			Set tItem=""
			For {
				Set tItem=$ORDER(^EnsHL7.Schema(tItem))
				Quit:tItem=""
			
				Set tQuotedItem = $SELECT(tItem?1.n1"."1.n:tItem,1:""""_tItem_"""")
			
				Set pGlobals("EnsHL7.Schema:("_tQuotedItem_")")=""
				Set pGlobals("EnsHL7.Description:("_tQuotedItem_")")=""
			}
		
			// Also, we build the list of mappings for ASTM schemas from ENSLIB
			Set tItem=""
			For {
				Set tItem=$ORDER(^EnsEDI.ASTM.Schema(tItem))
				Quit:tItem=""
			
				Set tQuotedItem = $SELECT(tItem?1.n1"."1.n:tItem,1:""""_tItem_"""")
			
				Set pGlobals("EnsEDI.ASTM.Schema:("_tQuotedItem_")")=""
				Set pGlobals("EnsEDI.ASTM.Description:("_tQuotedItem_")")=""
			}
			
			// Also, we build the list of mappings for X12 schemas from ENSLIB
			Set tItem=""
			For {
				Set tItem=$ORDER(^EnsEDI.X12.Schema(tItem))
				Quit:tItem=""
			
				Set tQuotedItem = $SELECT(tItem?1.n1"."1.n:tItem,1:""""_tItem_"""")
			
				Set pGlobals("EnsEDI.X12.Schema:("_tQuotedItem_")")=""
				Set pGlobals("EnsEDI.X12.Description:("_tQuotedItem_")")=""
			}

			// And, we build the list of mappings for EDI schemas from ENSLIB
			Set tItem=""
			For {
				Set tItem=$ORDER(^EnsEDI.Schema(tItem))
				Quit:tItem=""
			
				Set pGlobals("EnsEDI.Schema:("""_tItem_""")")=""
			}
			Set pGlobals("EnsEDI.Description:(""X"",""X12"")")=""
		
			// Other globals ... No longer mapped as of DDP102
			//Set pGlobals("Ens.Config.SearchTablePropD")=""
			//Set pGlobals("Ens.Config.SearchTablePropI")=""
		
			Set pGlobals("EnsDICOM.Dictionary")=""

		}

		Use tIO
	}
	Catch ex {
		Use tIO
		Throw ex
	}
	Quit
}

ClassMethod loadMessages(pTargetNS As %String, pVerbose As %Boolean = 0) As %Status [ Internal ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set tSC = $$$OK
	Set tOldNamespace = $Namespace
	Set $ZT="Trap"
	
	Set $Namespace = pTargetNS
	
	Do {
		
		// Find any matching CSP files
		Set tRS = ##class(%ResultSet).%New("%File:FileSet")
		If '$IsObject(tRS) Set tSC = %objlasterror Quit

		Set tLocaleDir = $$$LOCALEPATH
		Set tSC = tRS.Execute(tLocaleDir,"allmessages_*.xml")
		If $$$ISERR(tSC) Quit
		
		// Now, traverse the matching XML files
		While (tRS.Next()) {
			Set tFile = tRS.Data("Name")
			
			// Sanity checking on the filename (incl. ignoring the version separator ';' on VMS)
			If (tRS.Data("Type")'="F") || ($ZCVT($P($P(tFile,".",$L(tFile,".")),";"),"l")'="xml") Continue
			
			$$$REPORT(8,"+ Loading: "_tFile)
			
			// Load the messages
			Set tSC = $$Import^%occMsgXML(tFile)
			// Remove HealthShare domains if not in HSLIB
			// - note invoking this method for HSLIB will redundantly reload all messages into the appropriately mapped namespaces
			IF pTargetNS'=..#HSLIB {
				for tDomain="HS","HSErr" {kill ^IRIS.Msg(tDomain),^IRIS.MsgNames(tDomain)}
			}
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}
		
		// We ignore any errors during loading, other than to report them.
		Set tSC = $$$OK
	} While(0)
	
Exit
	Set $Namespace = tOldNamespace
	Quit tSC

Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod MultiEnsembleInstalled() As %Boolean
{
	Quit $o(^%SYS("Ensemble","InstalledNamespace",$o(^%SYS("Ensemble","InstalledNamespace",""))))'=""
}

/// Called by HealthShare, can't be private. This is an internal method for internal use only. It deletes databases.
/// pDBsToDelete - CORECGLOBALS (default), MAINGLOBALONLY, ALL
/// 		COREGLOBALS means delete main global database and Interoperability Temporary and Secondary DB if they exist and only if no other namespace references them.
/// 		MAINGLOBALONLY means delete main global database only and only if no other namespace references them.
/// 		ALL means delete all databases used by the namespace and only if no other namespace references them.
/// pRemoveResources 0 (default) or 1. If 1 then delete resources/roles named %DB_<NameOfDatabaseBeingDeleted>
/// 
ClassMethod deleteNamespace(pTargetNS As %String, pPurgeFiles As %Boolean = 0, pVerbose As %Boolean = 0, pDBsToDelete As %String = "COREGLOBALS", pRemoveResources As %Boolean = 0) As %Status [ Internal ]
{
	#define LOGERR(%a,%b) If $$$ISERR(%b) Set %a=$$$ADDSC(%a,%b) Do:pVerbose $system.OBJ.DisplayError(%b)
	#dim tDBDirectory As %String

	Set (tSC,tSC2)=$$$OK
	Try {
		// Check for namespace validity
		Quit:'..validateNamespace(.pTargetNS,0,.tSC)
		
		// Now, let's switch to %SYS and go delete this namespace
		New $NAMESPACE
		Set $NAMESPACE ="%SYS"
		
		$$$REPORT(0,"Deleting "_..namespaceProductionType()_" namespace: "_pTargetNS)

		// First, delete the CSP application
		Set tPortal = ..DetermineMgmtURLForNamespace(pTargetNS,0)
		Set tPortal = $P(tPortal,"/",1,$L(tPortal,"/")-1)
		Set tSC2 = ..deletePortal(tPortal,pPurgeFiles,pVerbose)
		If $$$ISERR(tSC2) Quit
		
		/*	Next, let's delete the namespace
			And requested databases
		*/
		Set tSC2 = ..getNSPSoleUseNonSysDBs(pTargetNS,pDBsToDelete,.tDBs)
		If $$$ISERR(tSC2) Quit

		// Remove the namespace from the config
		$$$REPORT(4,"* Removing namespace: "_pTargetNS)
		Set tSC2 = ##Class(Config.Namespaces).Delete(pTargetNS)
		If $$$ISERR(tSC2) Quit

		// Delete all databases and associated resources (if required) used only by the namespace
		Set tDBName = ""
 		Set tDBName = $order(tDBs(tDBName),1,tDBDir)
 		While (tDBName '=""){
	 		$$$REPORT(4,"* Removing Database "_tDBName)
			Set tSC2 = ##class(Config.Databases).Delete(tDBName)
			Quit:($$$ISERR(tSC2))
			If pPurgeFiles {
				$$$REPORT(6,"- Deleting Database "_tDBDir)
				Set tSC2 = ##class(SYS.Database).DeleteDatabase(tDBDir)
				Quit:($$$ISERR(tSC2))
				Set tDirectoriesToRemove(tDBDir)=""
			}
			If pRemoveResources && ##class(Security.Roles).%ExistsId($ZCVT("%DB_"_tDBName,"L")) {
				Set tSC2 = ##class(Security.Roles).Delete("%DB_"_tDBName)
				Quit:($$$ISERR(tSC2))
	 		}
	 		If pRemoveResources && ##class(Security.Resources).%ExistsId($ZCVT("%DB_"_tDBName,"L")) {
				Set tSC2 = ##class(Security.Resources).Delete("%DB_"_tDBName)
				Quit:($$$ISERR(tSC2))
	 		}
			Set tDBName = $order(tDBs(tDBName),1,tDBDir)
		}
		If $$$ISERR(tSC2) Quit

		If pPurgeFiles {	
			// Remove directories. Loop backwards so remove lower branches first but check if exists as well.
	 		$$$REPORT(4,"* Removing directories used by deleted databases")
			Set tDBDir = ""
 			Set tDBDir = $order(tDirectoriesToRemove(tDBDir),-1)
 			While (tDBDir '=""){
				// Delete the database directory
				$$$REPORT(6,"- Deleting Database Directory "_tDBDir)
				If ##class(%File).DirectoryExists(tDBDir) && '##class(%File).RemoveDirectoryTree(tDBDir) {
					$$$LOGERR(tSC,%objlasterror)
				}
				Set tDBDir = $order(tDirectoriesToRemove(tDBDir),-1)
			}
		}

		// Done!
		$$$REPORT(4,"* Complete!")
		
		// Any accumulated errors will be in tSC2
		Set tSC = $$$ADDSC(tSC,tSC2)

	} Catch ex { Set tSC2 = ex.AsStatus()}

	$$$LOGERR(tSC,tSC2)
Exit
	Quit tSC
}

/// Remove a CSP application
/// Called by HealthShare, can't be private
ClassMethod deletePortal(pPortal As %String, pPurgeFiles As %String, pVerbose As %Boolean = 0) As %Status [ Internal ]
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		If $NAMESPACE'="%SYS" {
			New $NAMESPACE
			Set $NAMESPACE = "%SYS"
		}
		
		Set:$E(pPortal,$L(pPortal))="/" pPortal = $E(pPortal,1,$L(pPortal)-1)
		If ##class(Security.Applications).Exists(pPortal) {
			Set tSC = ##class(Security.Applications).Get(pPortal,.tProperties)
			If $$$ISOK(tSC) {
				$$$REPORT(4,"* Removing management portal: "_pPortal)
				Set tSC = ##class(Security.Applications).Delete(pPortal)
				If $$$ISOK(tSC),pPurgeFiles {
					// Delete any CSP files
					Set tPortalDir = tProperties("Path")
					$$$REPORT(6,"- Deleting files in "_tPortalDir)
					If '##class(%File).RemoveDirectoryTree(tPortalDir) {
						Set tSC = %objlasterror
					}
				}
			}
		}
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Classmethod to ensure SearchTable classes are correctly deployed to each Interoperability namespace.
ClassMethod deploySearchTables(pTargetNS As %String, pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Set tStatus = $$$OK
	New $namespace
	Try {
		If $data(^%SYS("Ensemble", "Upgrade", "SearchTable")) {
			$$$REPORT(6,"- Converting existing SearchTable definitions")
			Set tStatus = ..upgradeSearchTables(pTargetNS, pVerbose)
			If $$$ISERR(tStatus) Quit
		}
		$$$REPORT(6,"- Validating all SearchTable metadata")
		Set $namespace = pTargetNS
		Set tClasses = ##class(%Library.ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tStatus = tClasses.Execute("Ens.VDoc.SearchTable")
		If $$$ISERR(tStatus) Quit
		#; Find all searchtables
		While tClasses.%Next() {
			Set tClassname = tClasses.%Get("Name")
			// Exclude Ens.VDoc.*, which should be superclasses, like Ens.VDoc.XMLSearchTable
			If $extract(tClassname, 1, 9) = "Ens.VDoc." Continue

			If '##class(%Dictionary.CompiledClass).%ExistsId(tClassname) {
				$$$REPORT(8,"- Skipping class '"_tClassname_"' as it has not been compiled")
			}
			Else {
				$$$REPORT(8, "- Regenerating metadata for " _ tClassname)
				Set tStatus = ##class(Ens.VDoc.SearchTableGenerator).ValidateSearchTableProperties(tClassname)
				If $$$ISERR(tStatus) Quit
			}
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Classmethod to upgrade SearchTable metadata which was mapped to ENSLIB in versions prior to 2010.2.
ClassMethod upgradeSearchTables(pTargetNS As %String, pVerbose As %Boolean = 0) As %Status
{
	#ifndef REPORT
	#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
	#endif
	#define DataLocation		^%SYS("Ensemble", "Upgrade", "SearchTable", "Data")
	#def1arg DataGlobal(%args)	^%SYS("Ensemble", "Upgrade", "SearchTable", "Data", %args)
	#define NSList				^%SYS("Ensemble", "Upgrade", "SearchTable", "Namespaces")
	#define PropStorageLocation(%base, %propName)	^Ens.Config.SearchTablePropD(%base, %propName)
	#define getProp(%list, %pos) $listget(%list, %pos)
	#define propClassname		 1
	#define propDerivation		 2
	#define propIndexType		 3
	#define propIsImplicit		 4			
	#define propPropId			 5
	#define propPropType		 6
	#define propStoreNulls		 7
	
	New %dataLoc
	Set tStatus = $$$OK
	Set tStartNS = $namespace
	Try {
		Set tUpgraded = $listfind($get($$$NSList), pTargetNS)
		If tUpgraded {
			$$$REPORT(8,"+ Skipping SearchTable upgrade for namespace '"_pTargetNS_"' as it has already been upgraded")
		}
		Else {
			Set $namespace = pTargetNS
			Set tBaseClass = ""
			For {
				Set tBaseClass = $order($$$DataGlobal(tBaseClass))
				Quit:(tBaseClass = "")
				Set tPropName = ""
				For {
					Set tPropName = $order($$$DataGlobal(tBaseClass, tPropName))
					Quit:(tPropName = "")
					Set tPropData = $get($$$DataGlobal(tBaseClass, tPropName))
					Set tPropId = +$$$getProp(tPropData, $$$propPropId)
					Set tSeenIDs(tBaseClass, tPropId) = ""
					Set tExists = ##class(Ens.Config.SearchTableProp).indexClassPropExists(tBaseClass, tPropName)
					If 'tExists { // We can replicate the old metadata safely, as there is no metadata present
						Set tDerivation = $$$getProp(tPropData, $$$propDerivation)
					
						Set tGenClass = $piece(tDerivation, "~", 1)
						Set tUpGenClass = $zconvert(tGenClass, "U")
						// Check that the class which created the SearchTable exists in this namespace
						Set tSourceClassExists = $data(^rINDEXCLASS(tUpGenClass))#2
						If tSourceClassExists { // should create the entry
							Set tProp = ##class(Ens.Config.SearchTableProp).%New()
							Set tProp.ClassExtent = tBaseClass
							Set tProp.ClassDerivation = tDerivation
							Set tProp.IndexType = $$$getProp(tPropData, $$$propIndexType)
							Set tProp.IsImplicit = $$$getProp(tPropData, $$$propIsImplicit)
							Set tProp.PropId = $$$getProp(tPropData, $$$propPropId)
							Set tProp.PropType = $$$getProp(tPropData, $$$propPropType)
							Set tProp.StoreNulls = $$$getProp(tPropData, $$$propStoreNulls)
							Set tProp.Name = tPropName
							$$$REPORT(8, "+ Adding SearchTable property '"_tProp.Name_"' in class '"_$piece(tProp.ClassDerivation, "~",1)_"' with PropId '"_tProp.PropId_"'")
							Set tStatus = tProp.%Save() 
							If $$$ISERR(tStatus) $$$ThrowStatus(tStatus)
						}
					}
					Else { // The metadata already exists locally... how would this be possible...?
						// We need to confirm that the values are the same, especially the derivation,
						// as the previous behaviour didn't always report this well
						Set tOldPropData = $get($$$PropStorageLocation(tBaseClass, tPropName))
						$$$REPORT(8, "+ Checking [%SYS] SearchTable property '"_tPropName_"' in class '"_$piece($$$getProp(tPropData, $$$propDerivation), "~")_"' with PropId '"_$$$getProp(tPropData, $$$propPropId)_"' against local property from class '"_$piece($$$getProp(tOldPropData, $$$propDerivation),"~")_"' with PropId '"_$$$getProp(tOldPropData,$$$propPropId)_"'")
						For i=1:1:7 {
							If $$$getProp(tOldPropData, i) '= $$$getProp(tPropData, i) {
								Set tStatus = $$$ERROR($$$GeneralError, "Conflict between existing and stored SearchTable data for property '"_tBaseClass_":"_tPropName_"' in namespace '"_pTargetNS_"'; Contact the WRC to resolve the issue")
								$$$ThrowStatus(tStatus)
							}
						}
						// All properties match
					}
				}
			}
			
			Set $$$NSList = $get($$$NSList)_$listbuild(pTargetNS)
		}
		
		Set tEnsNS = ""
		Set tAllDone = 1
		For {
			Set tEnsNS = $order(^%SYS("Ensemble", "InstalledNamespace", tEnsNS))
			Quit:(tEnsNS = "")
			If '$listfind($get($$$NSList), tEnsNS) {
				Set tAllDone = 0
				Quit
			}
		}
		If tAllDone {
			$$$REPORT(8, "+ All production-enabled namespaces have upgraded SearchTables, upgrade data will be cleared")
			Kill $$$DataLocation
		}
		Set $namespace = tStartNS
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
		Set $namespace = tStartNS
	}
	Quit tStatus
}

/// Ensure that the ^Ens.DocClassMap global has valid data during upgrades from versions where
/// the DocClassMap wasn't used.
ClassMethod upgradeDocClassMap(pTargetNS As %String, pVerbose As %Boolean = 0) As %Status
{
	#ifndef REPORT
	#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
	#endif
	
	Set tStatus = $$$OK
	Try {
		New $namespace
		Set $namespace = pTargetNS
		If $data(^Ens.DocClassMap) {
			$$$REPORT(8, "+ DocClassMap already present in namespace '"_$namespace_"'; no upgrade steps needed")
		}
		Else {
			#; Ensure we localise changes to the %Ensemble global variable in the DocClassMap code
			New %Ensemble
			Set %Ensemble = ""
			Set tRS = ##class(%Library.ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
			Set tStatus = tRS.Execute("Ens.VDoc.SearchTable")
			If $$$ISERR(tStatus) Quit
			While tRS.Next() {
				Set tClass = tRS.Get("Name")
				If $$$comClassKeyGet(tClass,$$$cCLASSabstract) Continue
				If $$$comClassKeyGet(tClass,$$$cCLASSnoextent) Continue
				#; Not using $parameter
				Set tDocClass = $$$comMemberKeyGet(tClass,$$$cCLASSparameter,"DOCCLASS",$$$cPARAMdefault)
				If tDocClass = "" Continue
				Set tSTList = ""
				If $$$comClassKeyGet(tDocClass,$$$cCLASSclasstype) = $$$cCLASSCLASSTYPESTREAM {
					Set tSTList = tSTList _ $listbuild("%Stream.Object")
				}
				Else {
					Set tSearchTableRoot = ##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(tClass)
					If tSearchTableRoot '= "" { Set tSTList = tSTList _ $listbuild(tSearchTableRoot) }
					If tClass '= tSearchTableRoot { Set tSTList = tSTList _ $listbuild(tClass) }
				}
				For i=1:1:$listlength(tSTList) {
					Set tSTClass = $listget(tSTList,i)
					Set tSC1 = ##class(Ens.DocClassMap).AddSearchTable(tDocClass,tSTClass,1)
					If $$$ISERR(tSC1) { $$$REPORT(10,"- Error DocClassMap for class '"_tSTClass_"' with DOCCLASS '"_tDocClass_"': "_$system.Status.GetErrorText(tSC1)) }
					Else { $$$REPORT(10,"- Added DocClassMap for class '"_tSTClass_"' with DOCCLASS '"_tDocClass_"'") }
				}
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Check whether any production-enabled UTC indices in a given namespace are in need of repair.
/// If <var>pLogToConsole</var> is true, we will also log a message to messages.log to indicate that
/// the <method>UpgradeUTCIndices</method> method in this class should be run for this namespace.
ClassMethod CheckUTCIndices(pTargetNS As %String = "", pVerbose As %Boolean = 1, pLogToConsole As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	If (pTargetNS = "") {
		Quit $$$ERROR($$$GeneralError,"Target namespace required")
	}
	Set tStatus = $$$OK
	New $namespace
	Try {
		Set $namespace = pTargetNS
		// Indices to repair
		Set tList = ..getUTCIndexGlobals()
		Set tNeedRepair = 0
		For i=1:1:$listlength(tList) {
			Set tIndexGlobal = $listget(tList,i)
			If ..indexNeedsRepair(tIndexGlobal) {
				$$$REPORT(6,"- UTC Index global "_tIndexGlobal_" in namespace "_pTargetNS_" needs to be repaired")
				Set tNeedRepair = 1
			}
		}
		If 'tNeedRepair {
			$$$REPORT(6,"- No UTC index globals need to be repaired.")
		}
		ElseIf pLogToConsole {
			$$$WarnMsg(..namespaceProductionType()_": ##class(%Library.EnsembleMgr).UpgradeUTCIndices() must be run for namespace '"_pTargetNS_"' as it contains UTC index data that needs to be repaired.")
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Get a list of the index globals containing UTC data that needs to be 
/// checked for incorrectly normalized values.
ClassMethod getUTCIndexGlobals() As %List [ Private ]
{
	Quit $lb("^Ens.MessageHeaderI(""TimeCreated"")") _
	$lb("^Ens.BusinessProcessI(""TimeCreated"")") _
	$lb("^Ens.Util.LogI(""TimeLogged"")") _
	$lb("^Ens.Util.IOLogI(""TimeReceived"")") _
	$lb("^Ens.Rule.RuleLogI(""TimeExecuted"")") _
	$lb("^Ens.EntMsgBank.MessageHeaderI(""TimeBanked"")") _
	$lb("^Ens.EntMsgBank.MessageHeaderI(""TimeCreated"")") _
	$lb("^Ens.EntMsgBank.LogI(""TimeLogged"")")
}

/// Ensure that timestamps of type Ens.DataType.UTC are correctly stored in various classes.
/// <var>pVerbose</var> controls whether output is written to the current device.
/// <var>pUseBatchMode</var> controls whether the operation should run in batch mode. This ensures
/// that the process uses a limited number of global buffers, which is likely to be crucial on a running system.
ClassMethod UpgradeUTCIndices(pTargetNS As %String = "", pVerbose As %Boolean = 1, pUseBatchMode As %Boolean = 1) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

#define IndexExtentGlobal(%i)	($extract($piece(%i,"("),1,*-1)_"D")
#define IndexClassname(%i)		$replace($extract($piece(%i,"("),2,*-1),".EntMsgBank.",".Enterprise.MsgBank.")
#define ClassSQLTable(%c)		($$$comClassKeyGet(%c,$$$cCLASSsqlschemaname)_"."_$$$comClassKeyGet(%c,$$$cCLASSsqltablename))

	If (pTargetNS = "") {
		Quit $$$ERROR($$$GeneralError,"Target namespace required")
	}
	Set tStatus = $$$OK
	New $namespace
	Try {
		Set $namespace = pTargetNS
		$$$REPORT(1,"- Running Interoperability UTC index upgrade in namespace '"_pTargetNS_"'")

		If pUseBatchMode {
			$$$REPORT(3,"Setting Batch Mode for process to 1")
			Set tOldBatchMode = ##class(%SYSTEM.Process).BatchFlag(1)
		}
		// Indices to repair
		Set tList = ..getUTCIndexGlobals()

		$$$REPORT(3,"Checking index globals...")

		For i=1:1:$listlength(tList) {
			Set tIndexGlobal = $listget(tList,i)
			// Add newline for readability
			$$$REPORT(0,"")
			If '..indexNeedsRepair(tIndexGlobal) {
				$$$REPORT(5,"- Index global "_tIndexGlobal_" does not need to be repaired; skipping conversion")
				Continue
			}
			Set tIsRuleLog = (tIndexGlobal = "^Ens.Rule.RuleLogI(""TimeExecuted"")")
			Set tExtentGlobal = $$$IndexExtentGlobal(tIndexGlobal)
			Set tLastTimestamp = $order(@tIndexGlobal@(""),-1)
			If tLastTimestamp = "" {
				$$$REPORT(5,"- Index global "_tIndexGlobal_" has no entries; skipping conversion")
				Continue
			}
			Set tFirstTimestamp = $order(@tIndexGlobal@(""))

			Set tLastID = $select(tIsRuleLog: $get(^Ens.Rule.RuleLogC("ExecutionId")), 1: $get(@tExtentGlobal))
			Set tFirstID = ""
			If (tFirstTimestamp '= "") {
				Set tFirstID = $order(@tExtentGlobal@(tFirstTimestamp,""))
			}
			Set tIDMsg = $select(tFirstID && tLastID: " and between IDs '"_tFirstID_"' and '"_tLastID_"'", tLastID: " with ID less than '"_tLastID_"'", 1: "")
			// Even if tLastID = "", there may be orphaned data in the index
			$$$REPORT(5,"- Performing conversion for index global "_tIndexGlobal_" between timestamps '"_tFirstTimestamp_"' and '"_tLastTimestamp_"'"_ tIDMsg)
			
			Set tNumFixed = 0
			Set tNumOrphans = 0
			Set tCount = 0
			Set tTS = tLastTimestamp
			For {
				Set tCount = tCount + 1
				If ((tCount # 20000) = 0) {
					Set tLoggingID = $order(@tIndexGlobal@(tTS,""))
					$$$REPORT(7,tCount _ " timestamps checked; Currently checking time '"_tTS_"' and ID '"_tLoggingID_"'...")
				}
				Set tMilliseconds = $piece(tTS,".",2)
				If "0" = $extract(tMilliseconds,*) {
					#; tTS has milliseconds with a trailing 0
					Set tMilliseconds = $reverse(+$reverse(tMilliseconds))
					Set tNewTS = $piece(tTS,".",1) _ $select(tMilliseconds = "0": "", 1: "." _ tMilliseconds)
					Set tID = ""
					For {
						Set tID = $order(@tIndexGlobal@(tTS,tID),1,tVal)
						Quit:("" = tID)
						If tIsRuleLog {
							Set tExecID = ""
							For {
								Set tExecID = $order(@tIndexGlobal@(tTS,tID,tExecID),1,tVal)
								Quit:("" = tExecID)
								If $data(@tExtentGlobal@(tID,tExecID)) {
									Set @tIndexGlobal@(tNewTS,tID,tExecID) = tVal
									Set tNumFixed = tNumFixed + 1
								}
								Else {
									Set tNumOrphans = tNumOrphans + 1
								}
							}
						}
						Else {
							If $data(@tExtentGlobal@(tID)) {
								Set @tIndexGlobal@(tNewTS,tID) = tVal
								Set tNumFixed = tNumFixed + 1
							}
							Else {
								Set tNumOrphans = tNumOrphans + 1
							}
						}
					}
					Kill @tIndexGlobal@(tTS)
				}
				Set tTS = $order(@tIndexGlobal@(tTS),-1)
				Quit:("" = tTS)
			}
			$$$REPORT(5,"+ Index conversion for global "_tIndexGlobal_" complete; fixed "_tNumFixed_" entries and removed "_tNumOrphans_" orphaned index entries")
		}
		$$$REPORT(1,"- Completed UTC index upgrade in namespace '"_pTargetNS_"'")
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
		$$$REPORT(1,"ERROR: Failed to complete upgrade due to error: " _ $system.Status.GetErrorText(tStatus))
	}
	If $data(tOldBatchMode)#2 Do ##class(%SYSTEM.Process).BatchFlag(tOldBatchMode)
	Quit tStatus
}

/// Helper method that uses a simple heuristic to loop over the index global supplied
/// in <var>pIndexGlobal</var> and check whether any entries include trailing zeroes.
/// By default, we only look at a thousand nodes, as the probability of encountering such a timestamp
/// is 10%, so 1000 should be more than enough entries to check.
ClassMethod indexNeedsRepair(pIndexGlobal As %String = "", pCount As %Integer = 1000) As %Boolean
{
	If (pIndexGlobal = "") || (pCount <= 0) Quit 0

	Set tNeedsRepair = 0
	Set tTS = ""
	For i=1:1:pCount {
		Set tTS = $order(@pIndexGlobal@(tTS))
		Quit:(tTS = "")
		If ("0" = $extract($piece(tTS,".",2),*)) {
			Set tNeedsRepair = 1
			Quit
		}
	}
	Quit tNeedsRepair
}

/// Convert searches saved as instances of CSPX.EnsMsgFilterForm to instances of EnsPortal.MsgFilter.SavedSearch.
ClassMethod convertCSPXSearches(pTargetNS As %String, pVerbose As %Boolean = 0) As %Status
{
	#ifndef REPORT
	#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
	#endif
	
	Set tStatus = $$$OK
	New $namespace
	Try {
		Set $namespace = pTargetNS
		Set tIndent = $select(pVerbose: 6, 1: 0)
		Set tStatus = ##class(EnsPortal.MsgFilter.SavedSearch).ConvertAllCSPXSearches(,,tIndent)
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Create the auditing events used by productions
ClassMethod CreateEnsembleAuditingEvents() As %Status
{
	Set tSC = $$$OK

	// Must be in namespace %SYS
	New $Namespace
	Set $Namespace = "%SYS"

	Try {
		// Define event: View contents of a message - enabled, system-defined, can be disabled
		Set Event = ..defineAuditViewMessageContents()
		If '(##class(Security.Events).Exists(Event)) {
			Set Descr = $$$GetMsg($$$EventsMsg, "EnsViewMsgContents")
			Set tSC = ##class(Security.Events).Create(Event, , , Descr, 1, 1)
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$ObjectScriptError, $ZE)
	}
	
	Try {
		// Define event: Resend a message - enabled, system-defined, can be disabled
		Set Event = ..defineAuditResendMessage()
		If '(##class(Security.Events).Exists(Event)) {
			Set Descr = $$$GetMsg($$$EventsMsg, "EnsResendMessage")
			Set tSC = ##class(Security.Events).Create(Event, , , Descr, 1, 1)
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$ObjectScriptError, $ZE)
	}

	Try {
		// Define event: Modify Production configuration - enabled, system-defined, can be disabled
		Set Event = ..defineAuditModifyProductionConfiguration()
		If '(##class(Security.Events).Exists(Event)) {
			Set Descr = $$$GetMsg($$$EventsMsg, "EnsModifyProductionConfig")
			Set tSC = ##class(Security.Events).Create(Event, , , Descr, 1, 1)
		}
	}
	Catch {
		Set tSC = $system.Status.AppendStatus(tSC, $$$ERROR($$$ObjectScriptError, $ZE))
	}

	Try {
		// Define event: Start or stop Production - enabled, system-defined, can be disabled
		Set Event = ..defineAuditStartStopProduction()
		If '(##class(Security.Events).Exists(Event)) {
			Set Descr = $$$GetMsg($$$EventsMsg, "EnsStartStopProduction")
			Set tSC = ##class(Security.Events).Create(Event, , , Descr, 1, 1)
		}
	}
	Catch {
		Set tSC = $system.Status.AppendStatus(tSC, $$$ERROR($$$ObjectScriptError, $ZE))
	}

	Try {
		// Define event: Modify System Default Setting - enabled, system-defined, can be disabled
		Set Event = ..defineAuditModifyDefaultSetting()
		If '(##class(Security.Events).Exists(Event)) {
			Set Descr = $$$GetMsg($$$EventsMsg, "EnsModifyDefaultSetting")
			Set tSC = ##class(Security.Events).Create(Event, , , Descr, 1, 1)
		}
	}
	Catch {
		Set tSC = $system.Status.AppendStatus(tSC, $$$ERROR($$$ObjectScriptError, $ZE))
	}


	Try {
		// Define event: Modify Schema - enabled, system-defined, can be disabled
		Set Event = ..defineAuditModifySchema()
		If '(##class(Security.Events).Exists(Event)) {
			Set Descr = $$$GetMsg($$$EventsMsg, "EnsModifySchema")
			Set tSC = ##class(Security.Events).Create(Event, , , Descr, 1, 1)
		}
	}
	Catch {
		Set tSC = $system.Status.AppendStatus(tSC, $$$ERROR($$$ObjectScriptError, $ZE))
	}

	Quit tSC
}

/// The defineAudit* methods below return literals with the names for the Interoperability auditing events 
/// with the format of a single string containing Source/Type/Name.
/// They return the values to be used when creating the audit events at installation/upgrade time by this class, 
/// and also to define macros by routine EnsConstants.inc in ENSLIB.
ClassMethod defineAuditModifyProductionConfiguration() As %String
{
	Quit "%Ensemble/%Production/ModifyConfiguration"
}

/// The defineAudit* methods below return literals with the names for the Interoperability auditing events 
/// with the format of a single string containing Source/Type/Name.
/// They return the values to be used when creating the audit events at installation/upgrade time by this class, 
/// and also to define macros by routine EnsConstants.inc in ENSLIB.
ClassMethod defineAuditStartStopProduction() As %String
{
	Quit "%Ensemble/%Production/StartStop"
}

/// The defineAudit* methods below return literals with the names for the Interoperability auditing events 
/// with the format of a single string containing Source/Type/Name.
/// They return the values to be used when creating the audit events at installation/upgrade time by this class, 
/// and also to define macros by routine EnsConstants.inc in ENSLIB.
ClassMethod defineAuditModifyDefaultSetting() As %String
{
	Quit "%Ensemble/%Production/ModifyDefaultSetting"
}

/// The defineAudit* methods below return literals with the names for the Interoperability auditing events 
/// with the format of a single string containing Source/Type/Name.
/// They return the values to be used when creating the audit events at installation/upgrade time by this class, 
/// and also to define macros by routine EnsConstants.inc in ENSLIB.
ClassMethod defineAuditModifySchema() As %String
{
	Quit "%Ensemble/%Schema/Modify"
}

/// The defineAudit* methods below return literals with the names for the Interoperability auditing events 
/// with the format of a single string containing Source/Type/Name.
/// They return the values to be used when creating the audit events at installation/upgrade time by this class, 
/// and also to define macros by routine EnsConstants.inc in ENSLIB.
ClassMethod defineAuditViewMessageContents() As %String
{
	Quit "%Ensemble/%Message/ViewContents"
}

/// The defineAudit* methods below return literals with the names for the Interoperability auditing events 
/// with the format of a single string containing Source/Type/Name.
/// They return the values to be used when creating the audit events at installation/upgrade time by this class, 
/// and also to define macros by routine EnsConstants.inc in ENSLIB.
ClassMethod defineAuditResendMessage() As %String
{
	Quit "%Ensemble/%Message/Resend"
}

/// Method to create production-related Resources and Roles, in addition to
/// upgrading existing users with access to the legacy portal through the
/// %Admin_Manage resource so that they retain full access to the new portal
/// after the installation completes.
ClassMethod InstallEnsembleSecurity(pIsPrimary As %Boolean = 1, pVerbose As %Boolean = 0) As %Status
{
	#ifndef REPORT
	#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
	#endif
	Try {

		#dim tNamespaceProductionType = ..namespaceProductionType()
		Set tStatus = $$$OK
		Set tNS = $namespace
		Set $namespace = "%SYS"
		
		$$$REPORT(6, "- Creating "_tNamespaceProductionType_" Resources")
		// Add newline before %Installer output starts
		$$$REPORT(0,"")
		
		Set tStatus = ..CreateEnsembleResources(,pVerbose)
		If $$$ISERR(tStatus) Quit
		
		// Delete old Java Business Hosts resource
		Set tSC = ##class(Security.Resources).Delete("%Ens_JBH")
		If $$$ISERR(tSC) && '$System.Status.Equals(tSC,$$$ResourceDoesNotExist) {
			$$$REPORT(0,"WARNING: Failed to delete deprecated resource '%Ens_JBH'. "_$System.Status.GetErrorText(tSC))
		}
		
		// Check whether a new resource has been assigned to any roles
		Set tStatus = ##class(Security.Resources).InUse("%Ens_ProductionRun",.tResourcesUsed)
		If $$$ISERR(tStatus) Quit
		
		Set tInstalledFlag = ..IsEnsembleInstalled()
		If 'tInstalledFlag {
			#; Don't set a namespace
			Set ^%SYS("Ensemble","InstalledNamespace")=""
		}
		
		$$$REPORT(6, "- Creating "_tNamespaceProductionType_" Roles")
		// Add newline before %Installer output starts
		$$$REPORT(0,"")
		
		Set tStatus = ..CreateEnsembleRoles(, pVerbose)
		If $$$ISERR(tStatus) Quit

		Set tStatus = ..addInteropMetricsSQLPrivileges(pVerbose)
		If $$$ISERR(tStatus) Quit
		
		If 'tInstalledFlag {
			Kill ^%SYS("Ensemble","InstalledNamespace","ENSEMBLE")
		}
		If 'tResourcesUsed { // Upgrade from system without Interoperability security
			$$$REPORT(6, "- Starting "_tNamespaceProductionType_" Security Upgrade")
			$$$REPORT(6, "- Adding '%EnsRole_Administrator' and '%EnsRole_Developer' roles to users with permissions on the '%Admin_Manage' resource")
			
			Set tStatus = ##class(Security.Resources).InUse("%Admin_Manage",.tInUse,.tRoles)
			If $$$ISERR(tStatus) Quit
		
			If tInUse {
				For i=1:1:$listlength(tRoles) {
					Set tRole = $listget(tRoles, i)
					Set tStatus = ..findUsersForRole(tRole, .tUsers,pVerbose)
					If $$$ISERR(tStatus) Quit
				}
				If $$$ISERR(tStatus) Quit
				Set tUsername = ""
				For {
					Set tUsername = $order(tUsers(tUsername))
					Quit:(tUsername = "")
					Kill tProperties
					Set tProperties = 1
					$$$REPORT(8, "+ Adding '%EnsRole_Administrator' and '%EnsRole_Developer' roles to user '"_tUsername_"'")
					Set tUserLow = $zcvt(tUsername,"L")
					Set tUser = ##class(Security.Users).%OpenId(tUserLow,,.tStatus)
					If $$$ISERR(tStatus) Quit
					Set tStatus = tUser.Roles.Insert("%EnsRole_Administrator")
					If $$$ISERR(tStatus) Quit
					Set tStatus = tUser.Roles.Insert("%EnsRole_Developer")
					If $$$ISERR(tStatus) Quit
					Set tStatus = tUser.%Save()
					If $$$ISERR(tStatus) Quit
				}
				If $$$ISERR(tStatus) Quit
			}
			$$$REPORT(6, "- Completed addition of '%EnsRole_Administrator' and '%EnsRole_Developer' roles to users with permissions on the '%Admin_Manage' resource")
		}
		Set $namespace = tNS
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If tNS '= $namespace {
		Set $namespace = tNS
	}
	Quit tStatus
}

/// Helper method to recursively locate all users who are assigned a role
/// directly and indirectly.
ClassMethod findUsersForRole(pRole As %String, ByRef pUsers, pVerbose As %Boolean = 0, pRoles As %List) As %String [ Internal, Private ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Try {
        Set pRoles = $G(pRoles)_$lb(pRole)		
        Set tDone = 0
		While 'tDone {
			Set tStatus = ##class(Security.Roles).InUse(pRole, .tInUse, .tUsers, .tMoreUsers, .tRoles, .tMoreRoles)
			If $$$ISERR(tStatus) Quit
			If tInUse {
				For i=1:1:$listlength(tUsers) {
					Set tUser = $listget(tUsers, i)
					If tUser '= "" Set pUsers(tUser) = ""
				}
				For i=1:1:$listlength(tRoles) {
					Set tRole = $listget(tRoles, i)
					Set foundAt = $listfind(pRoles,tRole)
					If foundAt>0 {
						Set str=tRole_" -> "_$listget(pRoles,*)
						For j=($listlength(pRoles)-1):-1:foundAt {
							Set str = str_" -> "_$listget(pRoles,j)
						}
						$$$REPORT(8,"WARNING: Circular role assignment detected. "_str)
						CONTINUE
					}
					If tRole '= "" {
						Set tStatus = ..findUsersForRole(tRole, .pUsers, pVerbose, pRoles)
						If $$$ISERR(tStatus) Quit
					}
				}
				If $$$ISERR(tStatus) Quit
				If ('tMoreUsers && 'tMoreRoles) Set tDone = 1
			}
			Else {
				Set tDone = 1
			}
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Add SQL privileges on core production-related tables to the base production-related Roles.
/// When possible, this should use %Installer-generated code.
ClassMethod addEnsembleSQLPrivileges(pNamespace As %String = "", pVerbose As %Boolean = 0) As %Status [ Internal ]
{
	/*	Role:						Tables:
		%EnsRole_Monitor			Ens_Util.Log
									Ens_Enterprise.MonitorClient
		%EnsRole_RulesDeveloper		Ens_Rule.RuleLog
									Ens_Rule.Log
		%EnsRole_Operator			Ens_Util.Log
									Ens_Rule.RuleLog
									Ens_Rule.Log
									Ens_Rule.DebugLog
									Ens.MessageHeader
									Ens.SuperSessionIndex
									Ens_Config.Credentials
									Ens.BusinessProcess
									Ens.BusinessProcessBPL
									Ens_Util.Calendar
									Ens_Enterprise.MonitorClient
									Ens_Enterprise_MsgBank.MessageHeader
									Ens_Enterprise_MsgBank.Log
									Ens_Enterprise_MsgBank.Node
									Ens_Util.Schedule
									Ens_Alerting.ManagedAlert
									EnsLib_Agent.Interface
									Ens_ServiceRegistry_External.Service
									Ens_ServiceRegistry_External.Attribute
									ISC_DM.IRISInteroperabilityPorts
		%EnsRole_WebDeveloper
			and
		%EnsRole_Administrator
									Message Contents
										EnsLib_HL7.Message
										EnsLib_HL7.SearchTable
										EnsLib_EDI_ASTM.Document
										EnsLib_EDI_ASTM.SearchTable
										EnsLib_EDI_EDIFACT.Document
										EnsLib_EDI_EDIFACT.SearchTable
										EnsLib_EDI_X12.Document
										EnsLib_EDI_X12.SearchTable
										EnsLib_EDI_XML.Document
										EnsLib_XML.SearchTable
										Ens.MessageBody
										EnsLib_RecordMap.Batch
										EnsLib_DICOM.Document
										EnsLib_ebXML.Message
										EnsLib_ebXML.MessageWithPayload
										EnsLib_ebXML.MessageTracking
										EnsLib_Printing.PrintJob
										EnsLib_Printing.PrintRequest
										EnsLib_SQL.Snapshot
										Ens.StreamContainer
										Ens.StringContainer
									Ens_Util.IOLog
		%EnsRole_AlertOperator		Ens_Alerting.ManagedAlert
		%EnsRole_RegistrySelect		Ens_ServiceRegistry_Public.Action
									Ens_ServiceRegistry_Public.Attribute
									Ens_ServiceRegistry_Public.Contact
									Ens_ServiceRegistry_Public.FileStore
									Ens_ServiceRegistry_Public.Service
		%EnsRole_RegistryManager	Ens_ServiceRegistry_Public.Internal
		%EnsRole_TempSQLDict		%Dictionary.ParameterDefinition
		%EnsRole_InteropEditorsAPI	%Dictionary.ClassDefinition_SubclassOf
										%Dictionary.ClassDefinition_Summary
										%Atelier_v1_Utils.Extension_UserAction
										%Atelier_v1_Utils.Extension_AfterUserAction
										%Atelier_v1_Utils.Extension_ExtensionEnabled
										%Atelier_v1_Utils.Extension_GetStatus
										%Atelier_v1_Utils.Extension_GetMenus
										%Studio_SourceControl.Interface_MenuItems
										%Studio_SourceControl.Interface_MainMenus
										Ens_Config.Production_Extent
										Ens_Config.Production_EnumerateConfigItems

		%EnsRole_WebDeveloper and %EnsRole_Administrator are also granted EXECUTE privileges on the Ens.IsASub stored procedure to allow for SearchTable searches.
		%EnsRole_Developer and %EnsRole_Administrator are also granted EXECUTE privileges on stored procedures needed by Studio for Ens_Config.Production_Extent.
	*/
	Try {
		Set tStatus = $$$OK
		Set tInitNS = $namespace
		If pNamespace = "" Quit
		Set $namespace = "%SYS"
	
		// tExtendedSearches contains the list of tables needed to perform basic extended searches.
		// SELECT privileges are assigned to roles which may view message content.
		Set tExtendedSearches = $lb("EnsLib_HL7.Message", "EnsLib_HL7.SearchTable", "EnsLib_EDI_ASTM.Document") _
										$lb("EnsLib_EDI_ASTM.SearchTable", "EnsLib_EDI_EDIFACT.Document", "EnsLib_EDI_EDIFACT.SearchTable") _
										$lb("EnsLib_EDI_X12.Document", "EnsLib_EDI_X12.SearchTable","EnsLib_EDI_XML.Document") _
										$lb("EnsLib_XML.SearchTable", "EnsLib_EDI_XML.SearchTable", "Ens.MessageBody", "EnsLib_RecordMap.Batch") _
										$lb("EnsLib_DICOM.Document", "EnsLib_ebXML.Message", "EnsLib_ebXML.MessageWithPayload") _
										$lb("EnsLib_ebXML.MessageTracking", "EnsLib_Printing.PrintJob", "EnsLib_Printing.PrintRequest") _
										$lb("EnsLib_SQL.Snapshot", "Ens.StreamContainer", "Ens.StringContainer") _
										$lb("Ens_Util.IOLog", $lb("EnsLib_Agent.Interface",0,"u"))
		// tDeployTables contains the list of tables needed for the Deployment Changes pages
		Set tDeployTables = $lb("Ens_Deployment.Token","Ens_Deployment.Invocations")
		Set tRoles("%EnsRole_Monitor") = $lb("Ens_Util.Log", "Ens_Enterprise.MonitorClient")
		Set tRoles("%EnsRole_RulesDeveloper") = $lb("Ens_Rule.RuleLog", "Ens_Rule.Log")
		Set tRoles("%EnsRole_Operator") = $lb("Ens_Util.Log", "Ens.MessageHeader", "Ens.SuperSessionIndex", "Ens_Config.Credentials", "Ens_Rule.RuleLog", "Ens_Rule.Log", "Ens_Rule.DebugLog") _ 
												$lb("Ens_Util.Calendar", "Ens.BusinessProcess", "Ens.BusinessProcessBPL", "Ens_Enterprise_MsgBank.MessageHeader") _
												$lb("Ens_Enterprise_MsgBank.Log", "Ens_Enterprise_MsgBank.Node", "Ens_Util.Schedule", "Ens_Enterprise.MonitorClient") _
												$lb("EnsLib_ITK_DTS_Framework.TransferLog", "EnsLib_ITK_Framework.FaultCode", "EnsLib_ITK_Framework.FaultVocabulary") _
												$lb("EnsLib_ITK_Framework.FaultVocabularyMap", "EnsLib_ITK_Setup.ConsumerServiceRegistry", "EnsLib_ITK_Setup.DistributionRules") _
												$lb("EnsLib_ITK_Setup.SenderRegistry", "EnsLib_ITK_Setup.ServiceDefinition", "EnsLib_ITK_Setup.SubscriptionRules") _
												$lb("EnsLib_ITK_Setup.SystemDefinition", "Ens_Alerting.ManagedAlert","EnsLib_Agent.Interface") _
												$lb("Ens_ServiceRegistry_External.Service","Ens_ServiceRegistry_External.Attribute") _
												$lb("ISC_DM.IRISInteroperabilityPorts")
		Set tRoles("%EnsRole_WebDeveloper") = tExtendedSearches
		Set tRoles("%EnsRole_Administrator") = tExtendedSearches_tDeployTables
		Set tRoles("%EnsRole_AlertOperator") = $lb("Ens_Alerting.ManagedAlert")
		Set tRoles("%EnsRole_RegistrySelect")=$lb("Ens_ServiceRegistry_Public.Action","Ens_ServiceRegistry_Public.Attribute","Ens_ServiceRegistry_Public.Contact","Ens_ServiceRegistry_Public.FileStore","Ens_ServiceRegistry_Public.Service")
		Set tRoles("%EnsRole_RegistryManager")=$lb($lb("Ens_ServiceRegistry_Public.Action",0,"siud"),$lb("Ens_ServiceRegistry_Public.Attribute",0,"siud"),$lb("Ens_ServiceRegistry_Public.Contact",0,"siud"),$lb("Ens_ServiceRegistry_Public.FileStore",0,"siud"),$lb("Ens_ServiceRegistry_Public.Internal",0,"siud"),$lb("Ens_ServiceRegistry_Public.Service",0,"siud"))
		Set tRoles("%EnsRole_TempSQLDict")=$lb($lb("%Dictionary.ParameterDefinition",0,"s"))
		#; Need this entry to add SP privs
		Set tRoles("%EnsRole_Developer") = ""
		Set tRoles("%EnsRole_InteropEditorsAPI") = ""
		// Procedures
		// tSearchProcs contains the stored procedures needed to execute SearchTable searches.
		// tStudioStoredProcs contains the stored procedures needed to execute SearchTable searches and SPs executed by Studio.
		Set tSearchProcs = $lb("Ens.IsASub")
		Set tStudioStoredProcs = $lb("Ens_Config.Production_Extent")
		Set tProcedures("%EnsRole_WebDeveloper") = tSearchProcs
		Set tProcedures("%EnsRole_Administrator") = tSearchProcs_tStudioStoredProcs
		Set tProcedures("%EnsRole_Developer") = tStudioStoredProcs
		Set tProcedures("%EnsRole_InteropEditorsAPI") = $lb("%Dictionary.ClassDefinition_SubclassOf", "%Dictionary.ClassDefinition_Summary","%Atelier_v1_Utils.Extension_UserAction","%Atelier_v1_Utils.Extension_AfterUserAction","%Atelier_v1_Utils.Extension_ExtensionEnabled","%Atelier_v1_Utils.Extension_GetStatus","%Atelier_v1_Utils.Extension_GetMenus","%Studio_SourceControl.Interface_MenuItems","%Studio_SourceControl.Interface_MainMenus","Ens_Config.Production_Extent","Ens_Config.Production_EnumerateConfigItems")
		
		Set tRole = ""
		For {
			Set tRole = $order(tRoles(tRole))
			Quit:(tRole = "")
			If '##class(Security.Roles).Exists(tRole,, .tStatus) Continue
			If $$$ISERR(tStatus) Quit
			$$$REPORT(6, "- Adding SQL privileges for role '"_tRole_"'")
			// Note that _Ensemble system user is used to grant privileges
			For i=1:1:$ll(tRoles(tRole)) {
				Set tTable = $lg(tRoles(tRole), i)
				If $ListValid(tTable) {
					Set tGrantable = +$lg(tTable, 2)
					Set tPriv = $lg(tTable, 3, "s")
					Set tTable = $lg(tTable, 1)
				}
				Else {
					Set tGrantable = 0
					Set tPriv = "s"
				}
				Set tSQLObject = "1,"_tTable
				Set tStatus = ..addSQLPrivilege(pNamespace, tSQLObject, tPriv, tRole, tGrantable)
			}
			If $$$ISERR(tStatus) Quit
			// Check for procedures
			If $data(tProcedures(tRole)) {
				Set tPriv = "e"
				For i=1:1:$ll(tProcedures(tRole)) {
					Set tProc = $lg(tProcedures(tRole),i)
					Set tSQLObject ="9,"_tProc
					Set tStatus = ..addSQLPrivilege(pNamespace, tSQLObject, tPriv, tRole)
					If $$$ISERR(tStatus) Quit
				}
				If $$$ISERR(tStatus) Quit
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $get(tInitNS) '= $namespace {
		Set $namespace = tInitNS
	}
	Quit tStatus
}

/// Add SQL privileges for the %InteropMetrics_Operator role
/// This is added separately from other Ensemble SQL privileges because it is in the %SYS namespace
ClassMethod addInteropMetricsSQLPrivileges(pVerbose As %Boolean = 0) As %Status [ Internal ]
{
	/*	Role:						Tables:
		%InteropMetrics_Operator	SYS_Monitor_Interop.ConsolidatedMetrics
									SYS_Monitor_Interop.Interface
									SYS_Monitor_Interop_Interface.Activity
									SYS_Monitor_Interop_Interface_Temp.ActivityByTime
									SYS_Monitor_Interop_Interface_Temp.CurrentActivity
	*/
#ifndef REPORT
	#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Try {
		Set tStatus = $$$OK
		New $namespace
		Set $namespace = "%SYS"
		If ##class(Security.Roles).Exists("%InteropMetrics_Operator",, .tStatus) && $$$ISOK(tStatus) {
			$$$REPORT(6, "- Adding SQL privileges for role '%InteropMetrics_Operator'")
			Set tTables=$lb("SYS_Monitor_Interop.ConsolidatedMetrics","SYS_Monitor_Interop.Interface","SYS_Monitor_Interop_Interface.Activity","SYS_Monitor_Interop_Interface_Temp.ActivityByTime","SYS_Monitor_Interop_Interface_Temp.CurrentActivity")
			For i=1:1:$ll(tTables) {
				Set tTable = $lg(tTables, i)
				Set tPriv = $S(tTable["_Temp.":"siud",1:"s")
				Set tSQLObject = "1,"_tTable
				Set tStatus = ..addSQLPrivilege("%SYS", tSQLObject, tPriv, "%InteropMetrics_Operator")
				If $$$ISERR(tStatus) Quit
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		$$$REPORT(0,"ERROR: Failed to add SQL privileges for role '%InteropMetrics_Operator' "_$System.Status.GetErrorText(tStatus))
	}
	Quit tStatus
}

/// Helper method to add privileges to users. Note that the default behaviour is to have
/// the _Ensemble system user grant privileges, and the GRANT option is false.
ClassMethod addSQLPrivilege(pNamespace As %String, pSQLObject As %String, pPrivilege As %String, pGrantee As %String, pGrantable As %Boolean = 0, pGrantor As %String = "_Ensemble") As %Status [ Private ]
{
	Set tStatus = $$$OK
	For i=1:1:$l(pPrivilege) {
		Set tPrivilege = $e(pPrivilege,i)
		If '##class(Security.SQLPrivileges).IDKeyExists(pNamespace, pSQLObject, tPrivilege, pGrantee, pGrantor) {
			Set tSQLPriv = ##class(Security.SQLPrivileges).%New()
			Set tSQLPriv.Namespace = pNamespace
			Set tSQLPriv.SQLObject = pSQLObject
			Set tSQLPriv.Grantable = pGrantable
			Set tSQLPriv.Grantee = pGrantee
			Set tSQLPriv.Privilege = tPrivilege
			Set tSQLPriv.Grantor = pGrantor
			Set tStatus = tSQLPriv.%Save()
			If $$$ISERR(tStatus) Quit
		}
	}
	Quit tStatus
}

ClassMethod CreateEnsembleResources(ByRef pVars, pLogLevel As %Integer, pInstaller As %Installer.Installer) As %Status [ CodeMode = objectgenerator ]
{
	Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "EnsembleResources")
}

ClassMethod CreateEnsembleRoles(ByRef pVars, pLogLevel As %Integer, pInstaller As %Installer.Installer) As %Status [ CodeMode = objectgenerator ]
{
	Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "EnsembleRoles")
}

/// Internal method subject to change that returns array of non
/// system databases used by a namespace.
/// The list can be limited using the pWhichDBs parameter:
/// CORECGLOBALS (default), MAINGLOBALONLY, ALL
/// 	COREGLOBALS means main global database and Interoperability Temporary and Secondary DB if they exist and only if no other namespace references them.
/// 	MAINGLOBALONLY means main global database only and only if no other namespace references it.
/// 	ALL means all databases used by the namespace and only if no other namespace references them.
/// It is the callers responsibility to be in %SYS and to handle any privilege restrictions.
ClassMethod getNSPSoleUseNonSysDBs(pTargetNS As %String, pWhichDBs As %String, Output pDBs As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Kill pDBs
	Try {
		// Get Namespace properties
		Set tSC=##Class(Config.Namespaces).Get(pTargetNS,.p)
		If $$$ISERR(tSC) Quit
		If (pWhichDBs="MAINGLOBALONLY") {
			Set tSC=##Class(Config.Databases).Get(p("Globals"),.p1)
			If $$$ISERR(tSC) Quit
			Set pDBs(p("Globals"))=p1("Directory")
			Set tCoreDBs = ","_p("Globals")_","
		} Else {
		 	Set tStmnt = ##class(%SQL.Statement).%New()
		 	Set tSC = tStmnt.%PrepareClassQuery("SYS.Database","List")
		 	If $$$ISERR(tSC) Quit
		 	Set tRS = tStmnt.%Execute("*")
		 	While tRS.%Next(.tSC) {
			 	Set tDBDirectory = tRS.%Get("Directory")
			 	#; Ensure don't include system databases
			 	If '##class(SYS.Database).IsSystemDB(tDBDirectory) {
					Set tDatabases($i(tDatabases)) = tDBDirectory
			 	}
		 	}
		 	If $$$ISERR(tSC) Quit
		 	For i=1:1:tDatabases {
		 		Set tSC = ##class(Config.Databases).DatabasesByDirectory("",tDatabases(i), .tDBNames)
		 		If $$$ISERR(tSC) Quit
				For j=1:1:$listlength($get(tDBNames)) {
					Set tDB = $listget(tDBNames, j)
					If (tDB '= "") && (tDB '= ..#ENSLIB) {
						Set pDBs(tDB) = tDatabases(i)
					}
				}
		 	}
		 	If $$$ISERR(tSC) Quit
		 	Set tCoreDBs = ","_p("Globals")_","_p("Globals")_..#TEMPSUFFIX_","_p("Globals")_..#SECONDARYSUFFIX_","
		}

		// Refine list to include only those used by the namespace and only that namespace
		Set tDBName = ""
		Set tDBName = $order(pDBs(tDBName))
		While (tDBName '="") {
			Set tSC = ##class(Config.Namespaces).NamespacesByDB(tDBName, .tNamespaces)
			If $$$ISERR(tSC) Quit
			Set tNumberNamespaces = $length($get(tNamespaces),",")
			If ((tNumberNamespaces'=1))||(($piece(tNamespaces, ",", 1))'=pTargetNS) {
				Kill pDBs(tDBName)
			} ElseIf (pWhichDBs'="ALL"){
				If tCoreDBs'[(","_tDBName_",") Kill pDBs(tDBName)
			}
			Set tDBName = $order(pDBs(tDBName))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Return tSC
}

XData EnsembleResources [ XMLNamespace = INSTALLER ]
{
<Manifest>
	<Var Name="ProductionType" Value="#{$classmethod(&quot;%Library.EnsembleMgr&quot;,&quot;namespaceProductionType&quot;)}"/>
		<!-- Activities - protect with USE -->
	<Resource Name="%Ens_Deploy" Description="Grants access to ${ProductionType} deployment activities" />
	<Resource Name="%Ens_DeploymentPkg" Description="Controls the construction of ${ProductionType} deployment packages" />
	<Resource Name="%Ens_DeploymentPkgClient" Description="Controls client side use of ${ProductionType} deployment packages" />
	<Resource Name="%Ens_TestingService" Description="Grants access to the ${ProductionType} Testing Service" />
	<Resource Name="%Ens_DTLTest" Description="Grants access to the DTL Testing utility" />
	<Resource Name="%Ens_ProductionRun" Description="Controls starting and stopping productions" />
	<Resource Name="%Ens_ConfigItemRun" Description="Controls starting and stopping configuration items" />
	<Resource Name="%Ens_MessageResend" Description="Grants access to Message Resend" />
	<Resource Name="%Ens_MessageEditResend" Description="Grants access to Message Edit and Resend" />
	<Resource Name="%Ens_MessageSuspend" Description="Controls the manual suspension of messages" />  
	<Resource Name="%Ens_MessageDiscard" Description="Controls discarding of queued and suspended messages" />
	<Resource Name="%Ens_MessageTrace" Description="Grants access to Message Trace" />
	<Resource Name="%Ens_MessageHeader" Description="Grants access to Message Header data" />
	<Resource Name="%Ens_MessageContent" Description="Grants access to the contents of messages" />
	<Resource Name="%Ens_MessageExport" Description="Grants access to export messages via the portal" />
	<Resource Name="%Ens_Purge" Description="Controls purging of ${ProductionType} data" />
	<Resource Name="%Ens_Dashboard" Description="Grants access to the ${ProductionType} Dashboard" />
	<Resource Name="%Ens_EventLog" Description="Grants access to the ${ProductionType} Event Log" />
	<Resource Name="%Ens_RuleLog" Description="Grants access to the Rule Log" />
	<Resource Name="%Ens_ProductionDocumentation" Description="Controls the creation of production documentation" />
	<Resource Name="%Ens_Portal" Description="Grants access to the ${ProductionType} Management Portal" />
	<Resource Name="%Ens_ViewFileSystem" Description="Grants access to the fileSelect dialog which allows the user to view the file system" />
	<Resource Name="%Ens_MsgBank_MessageHeader" Description="Grants access to Message Bank Header data" />
	<Resource Name="%Ens_MsgBank_MessageContent" Description="Grants access to the contents of messages in the Message Bank" />
	<Resource Name="%Ens_MsgBank_MessageResend" Description="Grants permission to resend messages from the Message Bank" />
	<Resource Name="%Ens_MsgBank_MessageEditResend" Description="Grants permission to edit and resend messages from the Message Bank" />
	<Resource Name="%Ens_MsgBank_MessageTrace" Description="Grants access to the Message Bank Visual Trace" />
	<Resource Name="%Ens_MsgBank_Dashboard" Description="Grants access to the Enterprise ${ProductionType} Monitor Page" />
	<Resource Name="%Ens_MsgBank_EventLog" Description="Grants access to the Message Bank Event Log" />
	<Resource Name="%Ens_AlertAdministration" Description="Grants access to administrative functions for ${ProductionType} Managed Alerts via USE" />
		<!-- Data - protect with READ, WRITE -->
	<Resource Name="%Ens_Agents" Description="Grants access to Agent browser page"/>
	<Resource Name="%Ens_Code" Description="Grants access to all ${ProductionType} classes and routines" />
	<Resource Name="%Ens_BPL" Description="Grants access to BPL" />
	<Resource Name="%Ens_DTL" Description="Grants access to DTL" />
	<Resource Name="%Ens_Rules" Description="Grants access to all ${ProductionType} Rules" />
	<Resource Name="%Ens_RoutingRules" Description="Grants access to Routing Rules" />
	<Resource Name="%Ens_BusinessRules" Description="Grants access to Business Rules" />
	<Resource Name="%Ens_RecordMap" Description="Grants access to ${ProductionType} RecordMaps" />
	<Resource Name="%Ens_ProductionConfig" Description="Grants access to production configuration activities" />
	<Resource Name="%Ens_EDISchema" Description="Grants access to EDI Schemas" />
	<Resource Name="%Ens_EDISchemaAnnotations" Description="Grants access to EDI Schema Annotations" />
	<Resource Name="%Ens_Queues" Description="Grants access to ${ProductionType} Queue data" />
	<Resource Name="%Ens_Jobs" Description="Grants access to ${ProductionType} Job data" />
	<Resource Name="%Ens_PurgeSchedule" Description="Grants access to scheduling of ${ProductionType} purge tasks" />
	<Resource Name="%Ens_PurgeSettings" Description="Grants access to change the settings used for manual purging of ${ProductionType} data"/>
	<Resource Name="%Ens_SystemDefaultConfig" Description="Grants access to ${ProductionType} System Default settings" />
	<Resource Name="%Ens_Credentials" Description="Grants access to ${ProductionType} Credentials" />
	<Resource Name="%Ens_ArchiveManager" Description="Grants access to the ${ProductionType} Archive Manager" />
	<Resource Name="%Ens_LookupTables" Description="Grants access to ${ProductionType} Lookup Tables" />
	<Resource Name="%Ens_MsgBankConfig" Description="Grants access to Message Bank configuration" />
	<Resource Name="%Ens_MsgBank" Description="Grants access to Message Bank status information" />
	<Resource Name="%Ens_WorkflowConfig" Description="Grants access to Workflow roles and users" />
	<Resource Name="%Ens_Alerts" Description="Grants access to view and edit ${ProductionType} Managed Alerts" />
	<Resource Name="%Ens_ITK" Description="Grants access to the ITK" />
	<Resource Name="%Ens_PubSub" Description="Grants access to the ${ProductionType} PubSub management pages" />
	<Resource Name="%Ens_RestrictedUI_SystemDefaultSettings" Description="Restricts a User to editing System Default Settings to those the user has USE privilege of." />
	<Resource Name="%Ens_SystemDefaultSettings_Port" Description="Allows a Portal user with limited UI System Default Role to manage the Port setting " />
	<Resource Name="%Ens_SystemDefaultSettings_IPAddress" Description="Allows a Portal user with limited UI System Default Role to manage the IPAddress setting " />
	<Resource Name="%Ens_SystemDefaultSettings_Server" Description="Allows a Portal user with limited UI System Default Role to manage the Server setting " />
	<Resource Name="%Ens_SystemDefaultSettings_AllowedIPAddresses" Description="Allows a Portal user with limited UI System Default Role to manage the AllowedIPAddresses setting " />
	<Resource Name="%Ens_SystemDefaultSettings_ActorPoolSize" Description="Allows a Portal user with limited UI System Default Role to manage the ActorPoolSize setting " />
	<Resource Name="%Ens_SystemDefaultSettings_PoolSize" Description="Allows a Portal user with limited UI System Default Role to manage the PoolSize setting " />
	<Resource Name="%Ens_SystemDefaultSettings_Enabled" Description="Allows a Portal user with limited UI System Default Role to manage the Enabled setting. The user is also required to hold the %Ens_ConfigItemRun:USE privilege " />
	<Resource Name="%Ens_SystemDefaultSettings_LogGeneralTraceEvents" Description="Allows a Portal user with limited UI System Default Role to manage the LogGeneralTraceEvents setting " />
	<Resource Name="%Ens_SystemDefaultSettings_Schedule" Description="Allows a Portal user with limited UI System Default Role to manage the Schedule setting " />
	<Resource Name="%Ens_SystemDefaultSettings_LogTraceEvents" Description="Allows a Portal user with limited UI System Default Role to manage the LogTraceEvents setting " />
	<Resource Name="%Ens_SettingsReportConfig" Description="Grants access to central Settings Report configuration" />
	<Resource Name="%Ens_PortSettingsReport" Description="Grants access to central Port Settings Report information" />
	<!-- Delete %Ens_MessageResubmit if it exists -->
	<Var Name="CurrentResource" Value="%Ens_MessageResubmit" />
	<Invoke Class="Security.Resources" Method="Exists" Return="ResourceExists">
	<Arg Value="${CurrentResource}" />
	</Invoke>
	<If Condition="${ResourceExists}">
	<Invoke Class="Security.Resources" Method="Delete" Return="ResourceDeleted">
	<Arg Value="${CurrentResource}" />
	</Invoke>
	<If Condition="${ResourceDeleted}">
	<Log Level="0" Text="Deleted Resource '${CurrentResource}'." />
	<Else />
	<Log Level="0" Text="Could not delete Resource '${CurrentResource}'." />
	</If>
	</If>
	<!-- Delete %Ens_SequenceManager if it exists -->
	<Var Name="CurrentResource" Value="%Ens_SequenceManager" />
	<Invoke Class="Security.Resources" Method="Exists" Return="ResourceExists">
	<Arg Value="${CurrentResource}" />
	</Invoke>
	<If Condition="${ResourceExists}">
	<Invoke Class="Security.Resources" Method="Delete" Return="ResourceDeleted">
	<Arg Value="${CurrentResource}" />
	</Invoke>
	<If Condition="${ResourceDeleted}">
	<Log Level="0" Text="Deleted Resource '${CurrentResource}'." />
	<Else />
	<Log Level="0" Text="Could not delete Resource '${CurrentResource}'." />
	</If>
	</If>
</Manifest>
}

XData EnsembleRoles [ XMLNamespace = INSTALLER ]
{
<Manifest>
	<!-- Roles -->
	<!-- %EnsRole_Operator -->
	<Var Name="CurrentRole" Value="%EnsRole_Operator" />
	<Var Name="ProductionType" Value="#{$classmethod(&quot;%Library.EnsembleMgr&quot;,&quot;namespaceProductionType&quot;)}"/>
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists." />
	<!-- Add Ens_ITK READ to %EnsRole_Operator -->
	<Var Name="CheckResources" Value="%Ens_ITK:R" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<!-- Add %Ens_PortSettingsReport READ to %EnsRole_Operator -->
	<Var Name="CheckResources" Value="%Ens_PortSettingsReport:R" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_SettingsReportConfig READ to %EnsRole_Operator -->
	<Var Name="CheckResources" Value="%Ens_SettingsReportConfig:R" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_Alerts WRITE to %EnsRole_Operator -->
	<Var Name="CheckResources" Value="%Ens_Alerts:W" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_Agents READ to %EnsRole_Operator -->
	<Var Name="CheckResources" Value="%Ens_Agents:R" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Remove %Ens_PurgeSchedule from %EnsRole_Operator -->
	<Var Name="SetResources" Value="%Ens_PurgeSchedule" />
	<Invoke Class="%Library.EnsembleMgr" Method="setResourcesForRole" Return="SetResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${SetResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${SetResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesRemoved" Value="#{$piece(&quot;${SetResourcesReturn}&quot;,$char(0),2)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${SetResourcesReturn}&quot;,$char(0),3)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to set resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; ((&quot;${ResourcesRemoved}&quot; '= &quot;&quot;) || (&quot;${ResourcesAdded}&quot; '= &quot;&quot;))}">
	<Log Level="0" Text="Modified role '${CurrentRole}': added '${ResourcesAdded}'; removed '${ResourcesRemoved}'." />
	</If>
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_Operator" 
		Description="${ProductionType} Operator" 
		Resources="%Ens_Portal:U,%Ens_ProductionRun:U,%Ens_ConfigItemRun:U,%Ens_MessageResend:U,%Ens_Dashboard:U,%Ens_ProductionConfig:R,%Ens_EventLog:U,%Ens_RuleLog:U,%Ens_MessageTrace:U,%Ens_MessageHeader:U,%Ens_Queues:R,%Ens_Jobs:R,%Ens_SystemDefaultConfig:R,%Ens_Credentials:R,%Ens_LookupTables:R,%Ens_MsgBank:R,%Ens_WorkflowConfig:R,%Ens_Alerts:RW,%Ens_MsgBank_MessageHeader:U,%Ens_MsgBank_MessageResend:U,%Ens_MsgBank_MessageTrace:U,%Ens_MsgBank_Dashboard:U,%Ens_MsgBank_EventLog:U,%Ens_ITK:R,%Ens_Agents:R,%Ens_PortSettingsReport:R,%Ens_SettingsReportConfig:R"
	/>
	</If>
	<!-- %EnsRole_RuleDeveloper -->
	<Var Name="CurrentRole" Value="%EnsRole_RulesDeveloper" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_RulesDeveloper"
		Description="${ProductionType} Rules Developer"
		Resources="%Ens_Portal:U,%Ens_Rules:RW,%Ens_RuleLog:U" 
	/>
	</If>
	<!-- %EnsRole_WebDeveloper -->
	<Var Name="CurrentRole" Value="%EnsRole_WebDeveloper" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists." />
	<!-- Add Ens_ITK WRITE to %EnsRole_WebDeveloper -->
	<Var Name="CheckResources" Value="%Ens_ITK:W" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_EDISchemaAnnotations READ and WRITE to %EnsRole_WebDeveloper -->
	<Var Name="CheckResources" Value="%Ens_EDISchemaAnnotations:RW" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_PubSub READ and WRITE to %EnsRole_WebDeveloper -->
	<Var Name="CheckResources" Value="%Ens_PubSub:RW" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_WebDeveloper"
		Description="${ProductionType} Web Developer" 
		RolesGranted="%EnsRole_Operator,%EnsRole_RulesDeveloper,%DB_ENSLIB"
		Resources="%Ens_DeploymentPkg:U,%Ens_TestingService:U,%Ens_DTLTest:U,%Ens_MessageEditResend:U,%Ens_MessageSuspend:U,%Ens_MessageDiscard:U,%Ens_MessageContent:U,%Ens_Purge:U,%Ens_ProductionDocumentation:U,%Ens_Code:RW,%Ens_ProductionConfig:W,%Ens_EDISchema:RW,%Ens_EDISchemaAnnotations:RW,%Ens_Queues:W,%Ens_Jobs:W,%Ens_LookupTables:W,%Ens_MsgBankConfig:RW,%Ens_WorkflowConfig:W,%Ens_Alerts:W,%Ens_MsgBank_MessageEditResend:U,%Ens_MsgBank_MessageContent:U,%Ens_ViewFileSystem:U,%Ens_ITK:W,%Ens_PubSub:RW"
	/>
	</If>
	<!-- %EnsRole_Developer -->
	<Var Name="CurrentRole" Value="%EnsRole_Developer" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists." />
	<!-- Add %Ens_PurgeSettings WRITE to %EnsRole_Developer -->
	<Var Name="CheckResources" Value="%Ens_PurgeSettings:W" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_Developer" 
		Description="${ProductionType} Developer" 
		RolesGranted="%Developer,%EnsRole_WebDeveloper"
		Resources="%Ens_PurgeSettings:W"
	/>
	</If>
	<!-- %EnsRole_Administrator -->
	<Var Name="CurrentRole" Value="%EnsRole_Administrator" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists." />
	<!-- Add %Ens_ITK WRITE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_ITK:W" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<!-- Add %Ens_PortSettingsReport READ & WRITE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_PortSettingsReport:RW" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_SettingsReportConfig READ & WRITE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_SettingsReportConfig:RW" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_EDISchemaAnnotations READ to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_EDISchemaAnnotations:R" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_PubSub READ to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_PubSub:R" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_AlertAdministration USE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_AlertAdministration:U" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_Agents WRITE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_Agents:W" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_MessageExport USE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_MessageExport:U" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_DeploymentPkgClient WRITE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_DeploymentPkgClient:W" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Add %Ens_PurgeSettings WRITE to %EnsRole_Administrator -->
	<Var Name="CheckResources" Value="%Ens_PurgeSettings:W" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${AddResourcesReturn}&quot;,$char(0),2)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to add resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; (&quot;${ResourcesAdded}&quot; '= &quot;&quot;)}">
	<Log Level="0" Text="Added resource '${ResourcesAdded}' to role '${CurrentRole}'." />
	</If>
	<!-- Set %Ens_PurgeSchedule:U for %EnsRole_Administrator -->
	<Var Name="SetResources" Value="%Ens_PurgeSchedule:U" />
	<Invoke Class="%Library.EnsembleMgr" Method="setResourcesForRole" Return="SetResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${SetResources}" />
	</Invoke>
	<Var Name="ErrorMessage" Value="#{$piece(&quot;${SetResourcesReturn}&quot;,$char(0),1)}" />
	<Var Name="ResourcesRemoved" Value="#{$piece(&quot;${SetResourcesReturn}&quot;,$char(0),2)}" />
	<Var Name="ResourcesAdded" Value="#{$piece(&quot;${SetResourcesReturn}&quot;,$char(0),3)}" />
	<If Condition="&quot;${ErrorMessage}&quot; '= &quot;&quot;">
	<Log Level="0" Text="Error updating role '${CurrentRole}'; failed to set resources '${ResourcesAdded}' due to error: ${ErrorMessage}" />
	</If>
	<If Condition="#{(&quot;${ErrorMessage}&quot; = &quot;&quot;) &amp;&amp; ((&quot;${ResourcesRemoved}&quot; '= &quot;&quot;) || (&quot;${ResourcesAdded}&quot; '= &quot;&quot;))}">
	<Log Level="0" Text="Modified role '${CurrentRole}': added '${ResourcesAdded}'; removed '${ResourcesRemoved}'." />
	</If>
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_Administrator"
		Description="${ProductionType} Administrator"
		RolesGranted="%EnsRole_Operator,%DB_ENSLIB"
		Resources="%Ens_DeploymentPkg:U,%Ens_DeploymentPkgClient:W,%Ens_Deploy:U,%Ens_TestingService:U,%Ens_DTLTest:U,%Ens_MessageEditResend:U,%Ens_MessageSuspend:U,%Ens_MessageDiscard:U,%Ens_MessageContent:U,%Ens_Purge:U,%Ens_MessageExport:U,%Ens_ProductionDocumentation:U,%Ens_Code:R,%Ens_ProductionConfig:W,%Ens_EDISchema:R,%Ens_EDISchemaAnnotations:R,%Ens_Queues:W,%Ens_Jobs:W,%Ens_PurgeSchedule:U,%Ens_PurgeSettings:W,%Ens_SystemDefaultConfig:W,%Ens_Credentials:W,%Ens_ArchiveManager:RW,%Ens_LookupTables:W,%Ens_MsgBankConfig:RW,%Ens_MsgBank:W,%Ens_WorkflowConfig:W,%Ens_Alerts:W,%Ens_MsgBank_MessageEditResend:U,%Ens_MsgBank_MessageContent:U,%Ens_ViewFileSystem:U,%Ens_ITK:W,%Ens_PubSub:R,%Ens_AlertAdministration:U,%Ens_Agents:W,%Ens_PortSettingsReport:RW,%Ens_SettingsReportConfig:RW"
	/>
	</If>
	<!-- %EnsRole_Monitor -->
	<Var Name="CurrentRole" Value="%EnsRole_Monitor" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_Monitor"
		Description="${ProductionType} Monitor"
		Resources="%Ens_Portal:U,%Ens_Dashboard:U,%Ens_MsgBank_Dashboard:U"
	/>
	</If>
	<!-- %EnsRole_PubSubDeveloper -->
	<Var Name="CurrentRole" Value="%EnsRole_PubSubDeveloper" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_PubSubDeveloper"
		Description="${ProductionType} PubSub Developer"
		Resources="%Ens_Portal:U,%Ens_PubSub:RW" 
	/>
	</If>
	<!-- %EnsRole_AlertOperator -->
	<Var Name="CurrentRole" Value="%EnsRole_AlertOperator" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_AlertOperator"
		Description="${ProductionType} user with Alert access"
		Resources="%Ens_Portal:U,%Ens_Alerts:RW" 
	/>
	</If>
	<!-- %EnsRole_AlertAdministrator -->
	<Var Name="CurrentRole" Value="%EnsRole_AlertAdministrator" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_AlertAdministrator"
		Description="${ProductionType} user with administrative Alert access"
		Resources="%Ens_AlertAdministration:U"
		RolesGranted="%EnsRole_AlertOperator"
	/>
	</If>
	<!-- %InteropMetrics_Operator -->
	<Var Name="CurrentRole" Value="%InteropMetrics_Operator" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%InteropMetrics_Operator"
		Description="User with ability to view Interoperability Usage Metrics"
	/>
	</If>
	<!-- Public Registry Roles -->
	<Var Name="CurrentRole" Value="%EnsRole_RegistryManager" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_RegistryManager"
		Description="${ProductionType} Administrator of the Public Registry"
	/>
	</If>
	<Var Name="CurrentRole" Value="%EnsRole_RegistrySelect" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_RegistrySelect"
		Description="${ProductionType} Role for viewing Public Registry tables"
	/>
	</If>
	<Var Name="CurrentRole" Value="%EnsRole_TempSQLDict" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; not updating." />
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_TempSQLDict"
		Description="${ProductionType} Role for temporary escalation to SQL Select on %Dictionary.ParameterDefinition for DTL Test users"
	/>
	</If>
	<Var Name="CurrentRole" Value="%EnsRole_InteropEditorsAPI" />
	<Invoke Class="Security.Roles" Method="Exists" Return="RoleExists">
	<Arg Value="${CurrentRole}" />
	</Invoke>
	<If Condition="${RoleExists}">
	<Log Level="0" Text="Role '${CurrentRole}' already exists; adding %Development:U if necessary." />
	<!-- Add %Development USE to %EnsRole_InteropEditorsAPI -->
	<Var Name="CheckResources" Value="%Development:U" />
	<Invoke Class="%Library.EnsembleMgr" Method="addResourcesToRole" Return="AddResourcesReturn">
	<Arg Value="${CurrentRole}" />
	<Arg Value="${CheckResources}" />
	</Invoke>
	</If>
	<If Condition="'${RoleExists}">
	<Role Name="%EnsRole_InteropEditorsAPI"
		Description="${ProductionType} Role for temporary escalation to hold %Development privilege and use of necessary stored procedures for the Interoperability Editors API"
		Resources="%Development:U"
	/>
	</If>
	</Manifest>
}

/// Helper method to check whether <var>pRole</var> already has the resource/permission pairs
/// in <var>pResources</var>, and adds them if not. Note that <var>pResources</var> should have the following format:
/// [Resource]:[Permissions]. Multiple pairs should be separated by commas.
/// The return value is in the format: [Error Message]_$char(0)_[Resources Added]
ClassMethod addResourcesToRole(pRole As %String = "", pResources As %String = "", Output pStatus As %Status) As %String [ Private ]
{
	Set pStatus = $$$OK
	Set tResourcesAdded = pResources
	Set tErrorMessage = ""
	Try {
		If (pRole = "") || '##class(Security.Roles).Exists(pRole,.tRoleObj,.pStatus) {
			Quit
		}
		Set pStatus = ..getExistingResources(pRole,.tExistingResources)
		If $$$ISERR(pStatus) Quit
		Merge tNewResources = tExistingResources
		Set tAddList = ""
		For i=$length(pResources,","):-1:1 {
			Set tPair = $piece(pResources,",",i)
			Set tResource = $piece(tPair,":",1)
			If (tResource = "") || '##class(Security.Resources).Exists(tResource,,.pStatus) {
				If $$$ISERR(pStatus) Quit
				Continue
			}
			Set tPermission = $piece(tPair,":",2)
			Set tPermissionExists = $data(tExistingResources(tResource),tOldPermissions)#2
			If tPermissionExists && (tOldPermissions '= "") && (tPermission = tOldPermissions) {
				Continue
			}

			Set tPermissionsInt = ##class(Security.Datatype.Permission).ExternalToInternal(tPermission) 
			If 'tPermissionsInt {
				Continue
			}
			If (tPermissionExists) {
				Set tOldPermissionsInt = ##class(Security.Datatype.Permission).ExternalToInternal(tOldPermissions)
				Set tNewPermissionsInt = $zboolean(tPermissionsInt,tOldPermissionsInt,7)
				If tNewPermissionsInt '= tOldPermissionsInt {
					Set tNewResources(tResource) =  ##class(Security.Datatype.Permission).InternalToExternal(tNewPermissionsInt)
					Set tAddList = tAddList _ $lb(tResource_":"_##class(Security.Datatype.Permission).InternalToExternal($zboolean(tPermissionsInt,tOldPermissionsInt,2)))
				}
			}
			Else {
				Set tNewResources(tResource) = tPermission
				Set tAddList = tAddList _ $lb(tPair)
			}
		}
		If $$$ISERR(pStatus) Quit
		If ($listlength(tAddList) = 0) {
			Set tResourcesAdded = ""
		}
		Else {
			Set tResourcesAdded = $listtostring(tAddList)
			Set tNewResString = ""
			Set tRes = ""
			For {
				Set tRes = $order(tNewResources(tRes),1,tPerm)
				Quit:(tRes = "")
				Set tNewResString = tNewResString _ "," _ tRes _ ":" _ tPerm
			}
			Set tProps("Resources") = $extract(tNewResString,2,*)
			Set pStatus = ##class(Security.Roles).Modify(pRole,.tProps)
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	If $$$ISERR(pStatus) {
		Set tErrorMessage = $system.Status.GetErrorText(pStatus)
	}
	Quit tErrorMessage _ $char(0) _ tResourcesAdded
}

/// Helper method to get the resources and permissions assigned to the role specified in <var>pRole</var>.
ClassMethod getExistingResources(pRole As %String = "", Output pExistingResources) As %Status [ Private ]
{
	Set tStatus = $$$OK
	Kill pExistingResources
	Try {
		If (pRole = "") || '##class(Security.Roles).Exists(pRole) Quit
		Set tRS = ##class(%Library.ResultSet).%New("Security.Roles:ListResources")
		Set tStatus = tRS.Execute(pRole)
		If $$$ISERR(tStatus) Quit
		While tRS.Next() {
			If (tRS.Get("Name") = pRole) {
				Set tResource = tRS.Get("Resource")
				Set tPermission = tRS.Get("Permission")
				If (tResource '= "") && (tPermission '= "") {
					Set pExistingResources(tResource) = tPermission
				}
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Helper method to specify the permissions for a set of resources in <var>pRole</var>.
/// <var>pResources</var> should have the following format: [Resource]:[Permissions]. 
/// Multiple pairs should be separated by commas. If <var>pRole</var> already has a set
/// of permission specified for a given resource, the permissions will be replaced by those 
/// specified. If the permission is omitted, then all permissions for the given resource will
/// be removed from the role.
/// The return value is in the format: [Error Message]_$char(0)_[Resources Removed]_$char(0)_[Resources Added]
ClassMethod setResourcesForRole(pRole As %String = "", pResources As %String = "", Output pStatus As %Status) As %String [ Private ]
{
	Set pStatus = $$$OK
	Set tResourcesAdded = pResources
	Set (tResourcesRemoved, tErrorMessage) = ""
	Try {
		If (pRole = "") || '##class(Security.Roles).Exists(pRole,,.pStatus) {
			Quit
		}
		Set pStatus = ..getExistingResources(pRole,.tResources)
		If $$$ISERR(pStatus) Quit
		Set tRemList = ""
		Set tAddList = ""
		For i=1:1:$length(pResources,",") {
			Set tPiece = $piece(pResources,",",i)
			Set tResource = $piece(tPiece,":",1)
			Set tPermission = $piece(tPiece,":",2)
			
			If $data(tResources(tResource),tOldPermission)#2 {
				If tOldPermission'=tPermission {
					If tPermission="" {
						Kill tResources(tResource)
					} Else {
						Set tResources(tResource)=tPermission
						Set tAddList = tAddList _ $lb(tResource_":"_$translate(tPermission,tOldPermission,""))
					}
					Set tRemList = tRemList _ $lb(tResource_":"_$translate(tOldPermission,tPermission,""))
				}
			} ElseIf tPermission'="" {
				Set tResources(tResource)=tPermission
				Set tAddList = tAddList _ $lb(tResource_":"_tPermission)
			}
		}
		If ($listlength(tRemList) = 0) && ($listlength(tAddList) = 0) {
			Set tResourcesRemoved = ""
			Set tResourcesAdded = ""
		}
		Else {
			Set tResourcesRemoved = $listtostring(tRemList)
			Set tResourcesAdded = $listtostring(tAddList)
			Set tNewResString = ""
			Set tRes = ""
			For {
				Set tRes = $order(tResources(tRes),1,tPerm)
				If tRes="" Quit
				Set tNewResString = tNewResString _ "," _ tRes _ ":" _ tPerm
			}
			Set tProps("Resources") = $extract(tNewResString,2,*)
			Set pStatus = ##class(Security.Roles).Modify(pRole,.tProps)
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	If $$$ISERR(pStatus) {
		Set tErrorMessage = $system.Status.GetErrorText(pStatus)
	}
	Quit tErrorMessage _ $char(0) _ tResourcesRemoved _ $char(0) _ tResourcesAdded
}

/// Set configuration flags in namespace pTargetNS,<br>
/// pVerbose report <br>
/// pFlagsSet is an array returned with flags set or it can be passed in to say which flags to set.<br>
/// This is called when a new namespace is made. Flags that need to be set during upgrade are set in UpgradeNamespace()<br>
ClassMethod setConfigFlags(ByRef pFlagsSet As %String, pTargetNS As %String = "", pVerbose As %Boolean = 0) As %Status [ Internal ]
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Set tSC = $$$OK
	Try {
		If (pTargetNS '="") {
			New $namespace
			Set $namespace = pTargetNS
		}
		If $D(pFlagsSet) {
			$$$REPORT(4,"* Setting flags from information passed in")
		} Else {
			#; Set upgrade related flags in UpgradeNamespace
			$$$REPORT(4,"* Setting new namespace flags")
			/* 
				It may be that this is a new namespace but its a mirror and has become the primary after previous primary set
			*/
			If $D(^Ens.Config("SyncCommit")) {
				$$$REPORT(4,"- Ens.Config SyncCommit already exists")
			} Else {
				$$$REPORT(4,"- Enabling SyncCommit for Business Services")
		 		Set pFlagsSet("SyncCommit")=1
			}
		}
		Merge ^Ens.Config = pFlagsSet
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// <p>Creates new database that  is used to store credential passwords and maps ^Ens.SecondaryData* to it.
/// This API is run by EnableNamespace() when creating new namespaces.</p>
/// <p>When you call this method, you must ensure that the production is not running and no changes are made to the credentials.<p>
/// <p>The new database is created in a subdirectory of the Namespace's default database for Globals. The name of the new database
/// and the subdirectory is the name of the Namespace's default database for Globals with "SECONDARY" appended. For example if the
/// default globals database is LABS then the new secondary database is called LABSSECONDARY. The new database is protected by a
/// resource named after the database (e.g. %DB_LABSSECONDARY) without public access. No user needs to have privileges to this resource.</p>
/// <p>After creating the secondary database, the call creates a global mapping for Ens.SecondaryData* and moves
/// any existing data to the new location.</p>
/// <p>An exception is that if Ens.SecondaryData* is already mapped before you make the call, the call does not create the database,
/// change the mapping, or move the data.</p>
/// <p>If the namespace globals database is mirrored, you must also ensure that the secondary database is also mirrored.
/// When you are creating a production-enabled namespace on a primary mirror and specify that the globals database is to be mirrored,
/// the secondary database is automatically marked as mirrored. But if you are creating a secondary database for any existing
/// namespace, you must explicitly set the secondary database to be mirrored. In this case, you should treat the secondary database
/// as an existing database when creating it on a backup mirror.</p>
/// This will not create the database if the default global database is remote.</p>
ClassMethod CreateNewDBForSecondary(pNamespace As %String = "", pVerbose As %Boolean = 0, pCheckValidNSP As %Boolean = 1) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Set tSC = $$$OK
	Set tGbl="Ens.SecondaryData*"
	
	$$$REPORT(4,"* Examining if secondary global mapping already configured")
	If '$$$IOwnAllRole {
		Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation) 
		If $$$ISERR(tSC) {$$$REPORT(4,$system.Status.GetErrorText(tSC)) Quit tSC}
	}
	If pCheckValidNSP,'..validateNamespace(.pNamespace,1,.tSC) {$$$REPORT(4,$system.Status.GetErrorText(tSC)) Quit tSC}
	Try {
		New $NAMESPACE
		Set $NAMESPACE=pNamespace
		Set tSC=##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)
		If $$$ISOK(tSC) {
			If (tState'=2),(tState'=3),(tState'=5),(tState>0) { /* If tState is <0 then mirror backup */
				Set tText="Cannot examine and change secondary global mapping for namespace '"_pNamespace_"' when production "_tProductionName_" is not stopped or suspended."
				$$$REPORT(6,"- "_tText)
				Set tSC = $$$ERROR($$$GeneralError,tText)
				Quit
			}
		} Else { 
			Quit
		}
		Set $NAMESPACE="%SYS"

/// Check if global already mapped and target database already exists, 

		If ##Class(Config.MapGlobals).Exists(pNamespace,tGbl) {
			$$$REPORT(6,"- Mapping for Seconday Data already exists")
			$$$REPORT(6,"- Not changing")
			Set tSC = $$$OK
			Quit
		} Else {
			$$$REPORT(6,"- Creating Seconday Data location")
		}
		
		If '##Class(Config.Namespaces).Exists(pNamespace,.tNamespaceObj) {
			Set tText = "- Failed to open Namespace definition "_pNamespace
			Set tSC = $$$ERROR($$$GeneralError,tText)
			$$$REPORT(6,tText)
			Quit
		}

		If '##Class(Config.Databases).Exists(tNamespaceObj.Globals,.tGlobalsObj) {
			Set tText = "Failed to access configuration for "_tNamespaceObj.Globals
			$$$REPORT(6,"- "_tText)
			Set tSC = $$$ERROR($$$GeneralError,tText)
			Quit
		}

		#; If default globals db is remote do not create secondary db
		If tGlobalsObj.Server'="" {
			Set tText = "Default Globals DB for Namespace is remote. Not creating Secondary Database"
			$$$REPORT(6,"- "_tText)
			Quit
		}

		#; Find if default globals DB is mirrored
		#dim tGlobalsdbOBJ = ""
		#dim tTargetDBName = tNamespaceObj.Globals_..#SECONDARYSUFFIX
		#dim tEndFailureMessage="- Failed to setup Secondary Data mapping for namespace "_pNamespace_" to "_tTargetDBName

		Set tGlobalsdbOBJ = ##class(SYS.Database).%OpenId(tGlobalsObj.Directory,,.tSC)
		If $$$ISERR(tSC) || ('$IsObject(tGlobalsdbOBJ)) {
			Set tText = "Failed to access database object for "_tGlobalsObj.Directory
			$$$REPORT(6,"- "_tText)
			$$$REPORT(6,tEndFailureMessage)
			Quit
		}

		If tGlobalsdbOBJ.Mirrored {
			Set tTargetMirrorDBName = tGlobalsdbOBJ.MirrorDBName_..#SECONDARYSUFFIX
			Set tTargetMirrorSetName = tGlobalsdbOBJ.MirrorSetName
		} Else {
			Set tTargetMirrorDBName = ""
			Set tTargetMirrorSetName = ""			
		}
		Set tGlobalsdbOBJ = ""

/// If database already defined then accept as OK and proceed to mapping else create

		If ##Class(Config.Databases).Exists(tTargetDBName,.tTargetDBOBJ) {
			Set tTargetDirectory = tTargetDBOBJ.Directory
			Set tText = "Will use existing Secondary Data database "_tTargetDBName_" using directory "_tTargetDirectory
			$$$REPORT(6,"- "_tText)
		} Else {
			Set tTargetDirectory=##class(%Library.File).SubDirectoryName(tGlobalsObj.Directory, $ZCVT(tTargetDBName,"L"), 1)
			If '##class(%File).DirectoryExists(tTargetDirectory) {
				$$$REPORT(6,"- Creating directory for new Secondary database "_tTargetDirectory)
				If '##class(%File).CreateDirectory(tTargetDirectory) {
					Set tText = "Failed to create directory "_tTargetDirectory
					$$$REPORT(6,"- "_tText)
					$$$REPORT(6,tEndFailureMessage)
					Set tSC = $$$ERROR($$$GeneralError,tText)
					Quit
				}
			}
			
/// If Database file already exist use it
			
			If ##class(%File).Exists(tTargetDirectory_$$$UCFILENAME_".DAT") {
				Set tText = $$$UCFILENAME_".DAT already exists in "_tTargetDirectory
				$$$REPORT(6,"- "_tText)
				Set tSC = ##class(SYS.Database).MountDatabase(tTargetDirectory)
				Set:($P($SYSTEM.Status.GetErrorCodes(tSC),",")=$$$ERRORCODE($$$AlreadyMounted)) tSC=$$$OK
				If $$$ISERR(tSC) {
					$$$REPORT(6,"- Failed to mount existing database for Secondary Data database "_tTargetDirectory)
					$$$REPORT(6,tEndFailureMessage)
					Quit
				}
			} Else {

/// Create the database

				$$$REPORT(6,"- Creating database for new Secondary Data database "_tTargetDirectory)
				If (tTargetMirrorDBName'="") {
					Set tText = "Will mark Secondary Data database "_tTargetDBName_" as mirrored with name "_tTargetMirrorDBName_" in mirror set "_tTargetMirrorSetName
					$$$REPORT(6,"- "_tText)
				}
				Set tSC = ##class(SYS.Database).CreateDatabase(tTargetDirectory,,,,,,tTargetMirrorDBName,tTargetMirrorSetName)
				If $$$ISERR(tSC) {
					$$$REPORT(6,"- Failed to create database for new Secondary Data database "_tTargetDirectory)
					$$$REPORT(6,tEndFailureMessage)
					Quit
				}
			}
			Set p("Directory")=tTargetDirectory
			Set tSC=##Class(Config.Databases).Create(tTargetDBName,.p)
			If $$$ISERR(tSC) {
				$$$REPORT(6,"- Failed to set configuration file for database "_tTargetDirectory)
				$$$REPORT(6,tEndFailureMessage)
				Quit		
			}
		}

/// Create/Assign resource here since DB definition may already exist if not mirrored or mirrored and primary

		If (tTargetMirrorDBName="")||($system.Mirror.IsMember()&&$system.Mirror.IsPrimary()) {
			Set tDBPermissions = ""
			Set tSC = ..assignResourceToDB("%DB_"_tTargetDBName,tTargetDirectory,tDBPermissions)
			If $$$ISERR(tSC) {
				$$$REPORT(6,"- Failed to assign resource "_"%DB_"_tTargetDBName_" to database "_tTargetDBName)
				$$$REPORT(6,tEndFailureMessage)
				Quit		
			} Else {
				$$$REPORT(6,"- Assigned resource "_"%DB_"_tTargetDBName_" to database "_tTargetDBName)
			}
			
/// Before creating the mapping see if any data in the globals covered by tGbl pattern and move over to new DB. Only if not mirrored or if primary
			
			Set tStatement = ##class(%SQL.Statement).%New(2)
	 		Set tSC = tStatement.%PrepareClassQuery("%SYS.GlobalQuery","NameSpaceList")
	 		If $$$ISERR(tSC) {
				$$$REPORT(6,"- Failed to run query to look for globals "_tGbl_" to move: "_$system.Status.GetErrorText(tSC))
				$$$REPORT(6,tEndFailureMessage)
				Quit		
			}

	 		Set tRSet = tStatement.%Execute(pNamespace,tGbl), tGblsToMoveAsString = ""
			While tRSet.%Next() {
				Set:'$D(tDefaultGlobalDirectory) tDefaultGlobalDirectory = ##class(%SYS.Namespace).GetGlobalDest(pNamespace)
				Set tOneGblToMove = tRSet.%Get("Name")
				If (tDefaultGlobalDirectory'=##class(%SYS.Namespace).GetGlobalDest(pNamespace,"^"_tOneGblToMove)) {
					Set tText = tOneGblToMove_" not in default globals database and not moving."
					Set tSC = $$$ERROR($$$GeneralError,tText)
				} Else {
					Set:($L(tGblsToMoveAsString)<30000) tGblsToMoveAsString = tGblsToMoveAsString_tOneGblToMove_" "
				}
				Set tMoveToGbl = "^|"_$C(34)_"^^"_tTargetDirectory_$C(34)_"|"_tOneGblToMove
				Set tGblToMove = "^|"_$C(34)_pNamespace_$C(34)_"|"_tOneGblToMove
				Set tSC = $$$OK
				Try {
					Set tLevel = $TLEVEL
					TSTART
						Merge @tMoveToGbl = @tGblToMove
						Kill @tGblToMove
					TCOMMIT
					$$$REPORT(6,"- Moved global "_tRSet.%Get("Name")_" to new database "_tTargetDirectory_" so that it will be accessible after the mapping change.")
				} Catch e { 
					If ($TLEVEL '= tLevel) TROLLBACK
					Set tSC = e.AsStatus()
				}
				Quit:$$$ISERR(tSC)
			}
			If $$$ISERR(tSC) {
				$$$REPORT(6,"- Failed to move global(s) matching "_tGbl_" : "_$system.Status.GetErrorText(tSC))
				$$$REPORT(6,tEndFailureMessage)
				Quit
			}
		}
		
/// Make overall mapping

		Kill p
		Set p("Database")=tTargetDBName
		Set tSC = ##Class(Config.MapGlobals).Create(pNamespace,tGbl,.p,,$$$CPFSave)
		If $$$ISERR(tSC) {
			$$$REPORT(6,"- ERROR: Failed to create global mapping "_tGbl_": "_$system.Status.GetErrorText(tSC))
			$$$REPORT(6,"- Failed to create global mapping "_tGbl_": "_$system.Status.GetErrorText(tSC)_" to database "_tTargetDBName_" in namespace "_pNamespace)
			$$$REPORT(6,tEndFailureMessage)
			Quit		
		} Else {
			$$$REPORT(6,"- Created global mapping "_tGbl_" for namespace "_pNamespace)
			Set tSC=..UpdateAndReloadCPF(pVerbose,pNamespace)
			If $$$ISERR(tSC) {
				$$$REPORT(6,"- ERROR: Failed to actiavte CPF change: "_$system.Status.GetErrorText(tSC))
				$$$REPORT(6,tEndFailureMessage)
				Quit
			}
			$$$REPORT(6,"- Activated CPF change")
		}
	} Catch e {Set tSC=e.AsStatus()}
	Quit tSC
}

/// Creates new non journalled database and maps ^IRIS.Temp.Ens* to it. This is called by EnableNamespace()<br>
/// This will not create the database if the default global database is remote.</p>
ClassMethod createNewDBForEnsTemp(pNamespace As %String = "", pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif
	Set tSC = $$$OK
	Quit:(pNamespace="") tSC
	#;The public ones are preferences that use PUBLIC R/W of CACHETEMP and mapped before new catchall
	Set tGblsPublic("IRIS.Temp.EnsPortal*")=""
	Set tGblsPublic("IRIS.Temp.EnsHostTotals")=""
	#;Added for future use:
	Set tGblsPublic("IRIS.Temp.EnsPublic*")=""
	#;Data mapped to new Temporary database
	Set tGbl="IRIS.Temp.Ens*"
	#dim tNamespaceProductionType = ..namespaceProductionType()
	$$$REPORT(4,"* Examining if "_tNamespaceProductionType_" temporary global mapping already configured")
	If '$$$IOwnAllRole {
		Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation) 
		If $$$ISERR(tSC) {$$$REPORT(4,$system.Status.GetErrorText(tSC)) Quit tSC}
	}
	Try {
		New $NAMESPACE
		Set $NAMESPACE=pNamespace				
		Set tSC=##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)
		If $$$ISOK(tSC) {
			If (tState'=2),(tState'=3),(tState'=5),(tState>0) { /* If tState is <0 then mirror backup */
				Set tText="Cannot examine and change "_tNamespaceProductionType_" temporary global mapping for namespace '"_pNamespace_"' when production "_tProductionName_" is not stopped or suspended."
				$$$REPORT(6,"- "_tText)
				Set tSC = $$$ERROR($$$GeneralError,tText)
				Quit
			}
		} Else { 
			Quit
		}
		Set $NAMESPACE="%SYS"

/// Check if temporary global database is not CACHETEMP, globals already mapped and target database already exists

		If '##Class(Config.Namespaces).Exists(pNamespace,.tNamespaceObj) {
			Set tText = "- Failed to open Namespace definition "_pNamespace
			Set tSC = $$$ERROR($$$GeneralError,tText)
			$$$REPORT(6,tText)
			Quit
		}
		
		If tNamespaceObj.TempGlobals'="IRISTEMP" {
			$$$REPORT(6,"- Temporary Global location is: "_tNamespaceObj.TempGlobals)
			$$$REPORT(6,"- Not changing")
			Set tSC = $$$OK
			Quit
		}		
		Set tGblPublic = $O(tGblsPublic("")), tAlreadyMapped = 0
		While tGblPublic '= "" {
			If ##Class(Config.MapGlobals).Exists(pNamespace,tGblPublic) {
				$$$REPORT(6,"- Mapping for "_tNamespaceProductionType_" temporary Data already exists"_ " - "_tGblPublic)
				$$$REPORT(6,"- Not changing")
				Set tSC = $$$OK, tAlreadyMapped = 1
				Quit
			}
			Set tGblPublic = $O(tGblsPublic(tGblPublic))
		}
		Quit:tAlreadyMapped
		If ##Class(Config.MapGlobals).Exists(pNamespace,tGbl) {
			$$$REPORT(6,"- Mapping for "_tNamespaceProductionType_" temporary Data already exists")
			$$$REPORT(6,"- Not changing")
			Set tSC = $$$OK
			Quit
		} Else {
			$$$REPORT(6,"- Creating "_tNamespaceProductionType_" temporary Data location")
		}

		If '##Class(Config.Databases).Exists(tNamespaceObj.Globals,.tGlobalsObj) {
			Set tText = "Failed to access configuration for "_tNamespaceObj.Globals
			$$$REPORT(6,"- "_tText)
			Set tSC = $$$ERROR($$$GeneralError,tText)
			Quit
		}

		#; If default globals db is remote do not create temporary db
		If tGlobalsObj.Server'="" {
			Set tText = "Default Globals DB for Namespace is remote. Not creating Temporary Database"
			$$$REPORT(6,"- "_tText)
			Quit
		}

		#; Find Resource protecting default globals DB
		#dim tGlobalsdbOBJ = ""
		#dim tTargetDBName = tNamespaceObj.Globals_..#TEMPSUFFIX
		#dim tEndFailureMessage="- Failed to setup "_tNamespaceProductionType_" temporary Data mapping for namespace "_pNamespace_" to "_tTargetDBName
		Set tGlobalsdbOBJ = ##class(SYS.Database).%OpenId(tGlobalsObj.Directory,,.tSC)
		If $$$ISERR(tSC) || ('$IsObject(tGlobalsdbOBJ)) {
			Set tText = "Failed to access database object for "_tGlobalsObj.Directory
			$$$REPORT(6,"- "_tText)
			$$$REPORT(6,tEndFailureMessage)
			Quit
		}
		Set tTargetResourceName=tGlobalsdbOBJ.ResourceName
		Set tGlobalsdbOBJ = ""

/// If database already defined then accept as OK and proceed to mapping else create

		If ##Class(Config.Databases).Exists(tTargetDBName,.tTargetDBOBJ) {
			Set tTargetDirectory = tTargetDBOBJ.Directory
			Set tText = "New "_tNamespaceProductionType_" temporary database already exists "_tTargetDBName_" using directory "_tTargetDirectory
			$$$REPORT(6,"- "_tText)
		} Else {
			Set tTargetDirectory=##class(%Library.File).SubDirectoryName(tGlobalsObj.Directory, $ZCVT(tTargetDBName,"L"), 1)
			If '##class(%File).DirectoryExists(tTargetDirectory) {
				$$$REPORT(6,"- Creating directory for new "_tNamespaceProductionType_" temporary database "_tTargetDirectory)
				If '##class(%File).CreateDirectory(tTargetDirectory) {
					Set tText = "Failed to create directory "_tTargetDirectory
					$$$REPORT(6,"- "_tText)
					$$$REPORT(6,tEndFailureMessage)
					Set tSC = $$$ERROR($$$GeneralError,tText)
					Quit	
				}
			}

/// If Database file already exist use it

			If ##class(%File).Exists(tTargetDirectory_$$$UCFILENAME_".DAT") {
				Set tText = $$$UCFILENAME_".DAT already exists in "_tTargetDirectory
				$$$REPORT(6,"- "_tText)
				Set tSC = ##class(SYS.Database).MountDatabase(tTargetDirectory)
				Set:($P($SYSTEM.Status.GetErrorCodes(tSC),",")=$$$ERRORCODE($$$AlreadyMounted)) tSC=$$$OK
				If $$$ISERR(tSC) {
					$$$REPORT(6,"- Failed to mount existing database for Temporary Data database "_tTargetDirectory)
					$$$REPORT(6,tEndFailureMessage)
					Quit
				}
				Set tSC = $$$OK
			} Else {

/// Create the database non journalled and assign resource the same as the default global database.

				$$$REPORT(6,"- Creating database for new "_tNamespaceProductionType_" Temporary Data database "_tTargetDirectory_". Protected by resource "_tTargetResourceName)
				Set tSC = ##class(SYS.Database).CreateDatabase(tTargetDirectory,,,,tTargetResourceName,2)
				If $$$ISERR(tSC) {
					$$$REPORT(6,"- Failed to create database for new "_tNamespaceProductionType_" temporary database "_tTargetDirectory)
					$$$REPORT(6,tEndFailureMessage)
					Quit
				}
			}
			Set p("Directory")=tTargetDirectory
			Set tSC=##Class(Config.Databases).Create(tTargetDBName,.p)
			If $$$ISERR(tSC) {
				$$$REPORT(6,"- Failed to set configuration file for database "_tTargetDirectory)
				$$$REPORT(6,tEndFailureMessage)
				Quit		
			}
		}
/// Make overall mapping. Keep Public in CACHETEMP first
		Kill p
		Set p("Database")="IRISTEMP"
		Set tGblPublic = $O(tGblsPublic("")), tMapError = 0
		While tGblPublic '= "" {
			Set tSC = ##Class(Config.MapGlobals).Create(pNamespace,tGblPublic,.p,,$$$CPFSave)
			If $$$ISERR(tSC) {
				$$$REPORT(6,"- ERROR: Failed to create global mapping "_tGblPublic_": "_$system.Status.GetErrorText(tSC))
				$$$REPORT(6,"- Failed to create global mapping "_tGblPublic_": "_$system.Status.GetErrorText(tSC)_" to database "_tTargetDBName_" in namespace "_pNamespace)
				$$$REPORT(6,tEndFailureMessage)
				Set tMapError = 1
				Quit
			} Else {
				$$$REPORT(6,"- Created global mapping "_tGblPublic_" for namespace "_pNamespace_" to remain in IRISTEMP")
			}
			Set tGblPublic = $O(tGblsPublic(tGblPublic))
		}
		Quit:tMapError
		If tSC {
			Set p("Database")=tTargetDBName
			Set tSC = ##Class(Config.MapGlobals).Create(pNamespace,tGbl,.p,,$$$CPFSave)	
		}
		If $$$ISERR(tSC) {
			$$$REPORT(6,"- ERROR: Failed to create global mapping "_tGbl_": "_$system.Status.GetErrorText(tSC))
			$$$REPORT(6,"- Failed to create global mapping "_tGbl_": "_$system.Status.GetErrorText(tSC)_" to database "_tTargetDBName_" in namespace "_pNamespace)
			$$$REPORT(6,tEndFailureMessage)
			Quit		
		} Else {
			$$$REPORT(6,"- Created global mapping "_tGbl_" for namespace "_pNamespace_" to new temporary database")
			Set tSC=..UpdateAndReloadCPF(pVerbose,pNamespace)
			If $$$ISERR(tSC) {
				$$$REPORT(6,"- ERROR: Failed to actiavte CPF change: "_$system.Status.GetErrorText(tSC))
				$$$REPORT(6,tEndFailureMessage)
				Quit
			}
			$$$REPORT(6,"- Activated CPF change")
		}
	} Catch e {Set tSC=e.AsStatus()}
	Quit tSC
}

/// Create the IRISMETRICS database for Interoperability Usage Metrics if it does not already exist,
/// ensure that it is added to the CPF file,
/// and create mappings from %SYS to the IRISMETRICS database.
/// Mappings from other databases to IRISMETRICS occurs when EnableNamespace is called.
ClassMethod CreateNewDBForMetrics(pVerbose As %Boolean = 0) As %Status
{
#ifndef REPORT
	#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	Set tSC = $$$OK
	Try {
		If '##Class(Config.Databases).Exists("IRISMETRICS",.tMetricsDB) {
			Set tMetricsDir = $$ComputeFullDBDir^%SYS.API("irismetrics")
			Set tMetricsInCPF = 0
		} Else {
			Set tMetricsDir = tMetricsDB.Directory
			Set tMetricsInCPF = 1
		}

		Set dirinfo=$$$dirinfo(tMetricsDir)
 		Set sfn=+dirinfo
 		If sfn<=-2 {
			$$$REPORT(8,"+ Creating IRISMETRICS database in "_tMetricsDir)
			Set sc1=$zu(140,4,tMetricsDir)
			If sc1'=0 {
				#;Directory does not exist
				If '##Class(%Library.File).CreateDirectoryChain(tMetricsDir) {
					$$$REPORT(0,"Failed to create IRISMETRICS directory in "_tMetricsDir)
					Quit
				}
			}
			Set Collation =5
			Set tSC = ##Class(SYS.Database).CreateDatabase(tMetricsDir,,,,,,,,,,,,Collation)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to create database: "_$system.Status.GetErrorText(tSC))
				Quit
			}	
			Set tSC = ..assignResourceToDB("%DB_IRISMETRICS",tMetricsDir,"")		
		} Else {
			$$$REPORT(8,"+ Database "_"IRISMETRICS"_" already exists ... skipping")
		}

		If 'tMetricsInCPF {
			$$$REPORT(8,"+ Adding Database IRISMETRICS in the CPF file")
			Set properties("Directory")=tMetricsDir
			Set tSC=##Class(Config.Databases).Create("IRISMETRICS",.properties,,$$$CPFSave+$$$CPFWrite+$$$CPFActivate+$$$CPFAvoidBackupDB)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to add database: "_$system.Status.GetErrorText(tSC))
				Quit
			}
		} Else {
			$$$REPORT(8,"+ Database "_"IRISMETRICS"_" already in the CPF file ... skipping")
		}

		If ##class(Security.Roles).Exists("%InteropMetrics_Operator") {
			Set tProps("Resources") = "%DB_IRISMETRICS:R,%Admin_Operate:U"
			Set tSC = ##class(Security.Roles).Modify("%InteropMetrics_Operator",.tProps)
			If $$$ISERR(tSC) {
				$$$REPORT(0,"ERROR: Failed to add resources for role %InteropMetrics_Operator : "_$system.Status.GetErrorText(tSC))
			}			
		}

		Set tSC = ..createGlobalMappings("%SYS", "IRISMETRICS",pVerbose, .pIsPrimary, 1)
		If $$$ISERR(tSC) {
			$$$REPORT(0,"ERROR: Failed to map metrics globals to IRISMETRICS: "_$system.Status.GetErrorText(tSC))
		}
	} Catch err {
		Set tSC = err.AsStatus()
		$$$REPORT(0,"ERROR: Exception thrown creating Metrics database: "_$system.Status.GetErrorText(tSC))
	}

	Quit tSC
}

/// Helper method to populate pIsPrimary.<br>
/// <li> pIsPrimary can be an array and will be calculated if not passed in</li>
/// Top node is whether this is a primary node or not. It is true if not in a mirror.<br/>
/// Subscripts are namespaces that have one or more mirrored databases.<br/>
ClassMethod populateIsPrimary(ByRef pIsPrimary) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tIsMirrorMember = $system.Mirror.IsMember()
		/* Calculate if top node not set */
		If (($D(pIsPrimary)#10)=0) {
			Set pIsPrimary = $S(tIsMirrorMember:$system.Mirror.IsPrimary(),1:1)
		}
		If tIsMirrorMember,'pIsPrimary,($D(pIsPrimary)=1) {
			Set tSC = ..findMirroredNamespaces(.tMirNamespaces)
			If $$$ISOK(tSC) {
				Merge pIsPrimary("MirrorNS") = tMirNamespaces
		 	}
		}
	} Catch err {
		Set tSC = err.AsStatus()	
	}	
	Quit tSC
}

ClassMethod moveToFromInstallTemp(pDirection As %String = "To", pNSP As %String = "", pGlbName As %String = "", Output pDataMoved As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If pNSP '= $NAMESPACE {
			New $NAMESPACE
			Set $NAMESPACE = pNSP
		}
		If pDirection = "To" {
			If $D(@pGlbName) {
				Set pDataMoved = 1
				Merge ^IRIS.Temp.EnsInstallTemp("%EnsembleMgr",pGlbName) = @pGlbName
				Kill @pGlbName
			}
		} ElseIf pDirection = "From" {
			If $D(^IRIS.Temp.EnsInstallTemp("%EnsembleMgr",pGlbName)) {
				Merge @pGlbName = ^IRIS.Temp.EnsInstallTemp("%EnsembleMgr",pGlbName)
				Kill ^IRIS.Temp.EnsInstallTemp("%EnsembleMgr",pGlbName)
			}
		}
	} Catch err {
		Set tSC = err.AsStatus()
	}						
	Quit tSC
}

ClassMethod deleteEnsTempData(ByRef pConsoleLog As %String) [ Internal, Private ]
{
	/* 
		We do it here so that can control how called. 
		Need to define the specific globals to remove of form ^IRIS.Temp.EnsXXXXX($namespace)
	*/

	#dim tEx As %Exception.AbstractException

	try {
		#; Find DB dir that we created ending in enstemp and only delete if match
		#dim tDefaultDBDir As %String = $$GetGlobalSourceDatabase^%SYS.SECURITY("Ens.JobStatus")
		#; want to take for example ../prod/ and return ../prod/prodenstemp/
		#dim tTemp As %Integer = ##class(%File).GetDirectoryLength(tDefaultDBDir)
		Set tTemp = ##class(%File).GetDirectoryPiece(tDefaultDBDir,tTemp)_$ZCVT(..#TEMPSUFFIX,"L")
		#dim tEnsTempDBDir As %String
		Set tEnsTempDBDir=tDefaultDBDir_$Select(($$$isVMS&&$Extract(tDefaultDBDir,*)="]"):"[.",1:"")_tTemp_$Extract(tDefaultDBDir,*)
		
		#; Quit if not made by internal API e.g. it could be in cachetemp directory
		If $$GetGlobalSourceDatabase^%SYS.SECURITY("IRIS.Temp.Ens")'=tEnsTempDBDir Quit
		
		#; Look for all IRIS.Temp.Ens* and delete if in tEnsTempDBDir
		#dim tStatement As %SQL.Statement
		#dim tRSet As %SQL.StatementResult
		
		#dim tGlobalNameSubscriptedByNamespace As %String
		
		Set tStatement = ##class(%SQL.Statement).%New(2)
 		$$$ThrowOnError(tStatement.%PrepareClassQuery("%SYS.GlobalQuery","NameSpaceList"))

 		Set tRSet = tStatement.%Execute($namespace,"IRIS.Temp.Ens*",1)
		While tRSet.%Next() {
			Set tGlobalNameSubscriptedByNamespace = "^"_tRSet.%Get("Name")_"("_$C(34)_$namespace_$C(34)_")"
			If $$GetGlobalSourceDatabase^%SYS.SECURITY($name(@tGlobalNameSubscriptedByNamespace))=tEnsTempDBDir{
				Kill @tGlobalNameSubscriptedByNamespace
			}
		}

	} catch tEx {
		#; If site decided to mirror the ENSTEMP then OK
		If tEx.Name '= "<PROTECT>" {
			Set pConsoleLog($increment(pConsoleLog))=$lb(1,"EnsembleTempCleanup: ERROR in namespace '"_$Namespace_"': "_$ZE_" tNameSpace='"_$G(tNameSpace)_"' $ZU(56,2)='"_$ZU(56,2)_"'")
		}
	}
}

/// This method returns an ordered list of ensemble namespaces in order of startup priority.<br>
/// The value returned is a $List structure of namespace and its startup relative priority. <br>
/// If a production is not set to Auto Start in a namespace the relative priority returned will be 0. <br>
/// The list returns the names of all production-enabled namespaces that the caller has READ access to
/// the global ^Ens.AutoStart in the the namespace. <br>
ClassMethod GetNamespacesByStartupPriority(Output pNamespacesByStartupPriority) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tPriority As %Integer
	#dim tNS,tProduction,tPriorities As %String
	#dim tWasAllowedToReadGlobal As %Boolean
	#dim tHaveAtLeastOneNamespace = ($Data(^%SYS("Ensemble","InstalledNamespace"))>1)

	Try {

		Set tNS="" For {
			Set tNS=$Order(^%SYS("Ensemble","InstalledNamespace",tNS)) If tNS="" Quit

			Set tProduction = ""
			Set tPriority = 0

			Try {
				Set tWasAllowedToReadGlobal = 1

				If ..canAccessGlobal(tNS,"Ens.AutoStart") {
					#;If we have a production set for auto start then look at priority
					Set tProduction = $Get(^|tNS|Ens.AutoStart,"")
					Set tPriority = +$Get(^|tNS|Ens.AutoStart("StartupPriority"),0)
				} Else {
					Set tWasAllowedToReadGlobal = 0
				}

			} Catch {
					#;A non security failure
					Set tProduction = ""
					Set tPriority = 0
			}

			#; Now record priority.
			If tWasAllowedToReadGlobal Set tPriorities(tPriority,tNS)=tProduction
		}

		#; Ensure we are not passed a stale list
		Kill pNamespacesByStartupPriority
		Set pNamespacesByStartupPriority = 0

		#; Higher priorities appear first in the list
		Set tPriority="" For {
			Set tPriority=$Order(tPriorities(tPriority),-1) If tPriority="" Quit
			Set tNS="" For {
				Set tProduction = ""
				Set tNS=$Order(tPriorities(tPriority,tNS),1,tProduction) If tNS="" Quit
				Set pNamespacesByStartupPriority($Increment(pNamespacesByStartupPriority))=$LB(tNS,tPriority,tProduction)
			}
		}

	} Catch e {
		Set tSC= e.AsStatus()
	}

	#; Safety check test to ensure we pass back all the namespaces
	#; If there were any production enabled namespaces. 
	#; If don't have tHaveAtLeastOneNamespace then pNamespacesByStartupPriority ought to be 0
	If $$$ISOK(tSC) && (pNamespacesByStartupPriority || tHaveAtLeastOneNamespace) {
		Set tSC = ..checkOrderedList(.pNamespacesByStartupPriority)
	}
	Quit tSC
}

/// internal helper method to check an ordered list of production-enabled namespaces does have all production-enabled namespaces
ClassMethod checkOrderedList(ByRef pNamespacesByStartupPriority As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tPriority As %Integer
	#dim tNS As %String

	Try {
		Kill ^||isc.ensAlphabetical
		Kill ^||isc.ensOrdered
		Merge ^||isc.ensAlphabetical = ^%SYS("Ensemble","InstalledNamespace")
		#; Don't want the top node ^%SYS("Ensemble","InstalledNamespace")=""
		ZKill ^||isc.ensAlphabetical
		Merge ^||isc.ensOrdered = pNamespacesByStartupPriority
		ZKill ^||isc.ensOrdered
		Kill tNS

		For tPriority = 1:1:$G(pNamespacesByStartupPriority,0) {
			Set tNS = $LG(^||isc.ensOrdered(tPriority))
			Kill ^||isc.ensAlphabetical(tNS)
			Kill ^||isc.ensOrdered(tPriority)
		}
		If $Data(^||isc.ensAlphabetical)||$Data(^||isc.ensOrdered) {
			Set tSC = $$$ERROR($$$GeneralError,"Failed to order all Ensemble namespaces by priority or group.")
		}
	} Catch e {
		Set tSC= e.AsStatus()
	}

	Kill ^||isc.ensAlphabetical
	Kill ^||isc.ensOrdered

	Quit tSC
}

/// Internal helper method to identify if user has access to the global
/// Error handling to be trapped by caller.
ClassMethod canAccessGlobal(pNamespace As %String = {$NAMESPACE}, pGlobal As %String = "", pSubscript As %String = "", pAccessMode As %String = "READ") As %Boolean [ Internal ]
{
	#dim tImpliedNamespace, tImpliedNamespaceInfo, tResource As %String

	Set tImpliedNamespace = ##class(%SYS.Namespace).GetGlobalDest(pNamespace,pGlobal,pSubscript)
	If $Length(tImpliedNamespace,"^")<2 Set tImpliedNamespace="^"_tImpliedNamespace
	If $Length(tImpliedNamespace,"^")<3 Set tImpliedNamespace="^"_tImpliedNamespace

	Kill tImpliedNamespaceInfo
	Do GetNSInfo^%SYS.NAMESPACE(tImpliedNamespace, .tImpliedNamespaceInfo)
	Set tResource = $Get(tImpliedNamespaceInfo("Resource"))

	Quit $SYSTEM.Security.Check(tResource,pAccessMode)
}

/// Query to display order of productions set for auto start by order of startup priority for those namespaces caller allowed to inspect.
/// This Query is used in EnsPortal.AutoStartProduction but is only shown if the user has access to all. [GetNamespacesByStartupPriority() does not return an error]
Query ListProductionsByAutoStartPriority() As %Query(ROWSPEC = "Production:%String(MAXLEN=128),StartupPriority:%String,Namespace:%String(MAXLEN=128)") [ SqlProc ]
{
}

ClassMethod ListProductionsByAutoStartPriorityExecute(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	#; Not handling errors since the list could be limited due to privileges
	Do ..GetNamespacesByStartupPriority(.qHandle)
	#; Since the list returned is an ordered list with the top node being the code we zero for Fetch()
	Set qHandle = 0
	Quit $$$OK
}

ClassMethod ListProductionsByAutoStartPriorityFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set Row="",AtEnd=0
	#dim tNamespace, tStartupPriority, tProduction As %String
	#dim tNext = $Order(qHandle(qHandle))
	While (tNext '= "") && (Row = "") {
		#; Only return non empty auto start production rows
		Set tProduction = $LIST(qHandle(tNext),3)
		Set tStartupPriority = $LIST(qHandle(tNext),2)
		Set tNamespace = $LIST(qHandle(tNext),1)
		If tProduction '="" {
			Set Row = $LB(tProduction,tStartupPriority,tNamespace)
		} Else {
			/*
				This is to account for productions set to start
				with same priority as set in namespaces with no auto start.
				Expected to be those with no priority/priority of 0.
			*/
			Set tNext = $Order(qHandle(qHandle))
		}
		Set qHandle = tNext
	}
	If tNext = "" Set AtEnd = 1
	Quit $$$OK
}

ClassMethod ListProductionsByAutoStartPriorityClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// This method returns an ordered list of production-enabled namespaces in order of Shutdown Group.<br>
/// The value returned is a $List structure of namespace and its relative shutdown group. <br>
/// If a production is not assigned a shutdown group in a namespace the relative shutdown group
/// returned will be 2 (see $$$ensDefaultShutdownGroup in EnsConstants.inc). <br>
/// The list returns the names of all production-enabled namespaces that the caller has READ access to
/// the global/subscript given by $$$EnsProdShutdownGroup in the the namespace $$$EnsConfigurationGbl("ShutdownGroup")]. <br>
ClassMethod GetNamespacesByShutdownGroup(Output pNamespacesByShutdownGroup) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tShutdownGroup As %Integer
	#dim tNS,tProduction,tGroups As %String
	#dim tWasAllowedToReadGlobal As %Boolean
	#dim tWorkingNS = $namespace

	Try {

		Set tNS="" For {
			Set tNS=$Order(^%SYS("Ensemble","InstalledNamespace",tNS)) If tNS="" Quit

			Set tProduction = ""
			Set tShutdownGroup = 2

			Try {
				Set tWasAllowedToReadGlobal = 1
				If ..canAccessGlobal(tNS,"^Ens.Configuration","ShutdownGroup") {
					#;Find production shutdown group for a given namespace
					Try {
						Set $namespace = tNS
						Set tShutdownGroup = ##class(Ens.Director).GetRunningProductionShutdownGroup(.tProduction)
					} Catch {Set tWasAllowedToReadGlobal = 0}
				} Else {
					Set tWasAllowedToReadGlobal = 0
				}

			} Catch {
					#;A non security failure
					Set tProduction = ""
					Set tShutdownGroup = 2
			}

			#; Now record shutdown group
			If tWasAllowedToReadGlobal Set tGroups(tShutdownGroup,tNS)=tProduction
		}
		Set $namespace = tWorkingNS

		#; Ensure we are not passed a stale list
		Kill pNamespacesByShutdownGroup
		Set pNamespacesByShutdownGroup = 0

		#; Lower shutdown groups appear first in the list
		Set tShutdownGroup="" For {
			Set tShutdownGroup=$Order(tGroups(tShutdownGroup)) If tShutdownGroup="" Quit
			Set tNS="" For {
				Set tProduction = ""
				Set tNS=$Order(tGroups(tShutdownGroup,tNS),1,tProduction) If tNS="" Quit
				Set pNamespacesByShutdownGroup($Increment(pNamespacesByShutdownGroup))=$LB(tNS,tShutdownGroup,tProduction)
			}
		}

	} Catch e {
		Set tSC= e.AsStatus()
	}

	#; Safety check test to ensure we pass back all the namespaces.
	If $$$ISOK(tSC) {
		Set tSC = ..checkOrderedList(.pNamespacesByShutdownGroup)
	}
	Quit tSC
}

/// Query to display order of productions ordered by Shutdown Group for those namespaces caller allowed to inspect.
/// This Query is used in EnsPortal.ProductionShutdownGroup but is only shown if the user has access to all production namesapces. [GetNamespacesByShutdownGroup() does not return an error]
Query ListProductionsByShutdownGroup() As %Query(ROWSPEC = "Production:%String(MAXLEN=128),ShutdownGroup:%String,Namespace:%String(MAXLEN=128)") [ SqlProc ]
{
}

ClassMethod ListProductionsByShutdownGroupExecute(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	#; Not handling errors since the list could be limited due to privileges
	Do ..GetNamespacesByShutdownGroup(.qHandle)
	#; Since the list returned is an ordered list with the top node being the code we zero for Fetch()
	Set qHandle = 0
	Quit $$$OK
}

ClassMethod ListProductionsByShutdownGroupFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set Row="",AtEnd=0
	#dim tNamespace, tStartupGroup, tProduction As %String
	#dim tNext = $Order(qHandle(qHandle))
	While (tNext '= "") && (Row = "") {
		#; Only return non empty auto start production rows
		Set tProduction = $LIST(qHandle(tNext),3)
		Set tStartupGroup = $LIST(qHandle(tNext),2)
		Set tNamespace = $LIST(qHandle(tNext),1)
		If tProduction '="" {
			Set Row = $LB(tProduction,tStartupGroup,tNamespace)
	} Else {
			// This is to account where a production has yet to be run
			Set tNext = $Order(qHandle(qHandle))
		}
		Set qHandle = tNext
	}
	If tNext = "" Set AtEnd = 1
	Quit $$$OK
}

ClassMethod ListProductionsByShutdownGroupClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// This method is called by EnableNamespace (via dataUpgradeSteps) to update Activity Dashboard meta data.
ClassMethod upgradeDashboards(pTargetNS As %String, pVerbose As %Boolean = 0, pValidateNamespace As %Boolean = 1) As %Status
{
#ifndef REPORT
#define REPORT(%l,%x) Write:pVerbose !,?%l,%x
#endif

	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {
		// Check for namespace validity
		If pValidateNamespace && '..validateNamespace(.pTargetNS,1,.tSC) Quit
		
		// Switch namespace
		If $NAMESPACE'=pTargetNS {
			New $NAMESPACE	
			Set $NAMESPACE = pTargetNS
		}

		/* Cleanup old folder name item first if exists*/
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem("Ens/DeepSee/ActivityVolumeAndDuration.dashboard")
		If $$$ISERR(tSC) && pVerbose Do $system.OBJ.DisplayError(tSC)

		/* Generate Meta Data using direct calls rather than compilation */

		$$$REPORT(4,"") /* make 'Importing:' message appear on new line if verbose output*/
		Set tSC = ##class(Ens.DeepSee.ActivityVolumeAndDurationDashboard).%Process(pVerbose)
		If $$$ISERR(tSC) && pVerbose Do $system.OBJ.DisplayError(tSC)
		Set tSC = ##class(%DeepSee.KPIProjection).CreateProjection("Ens.DeepSee.ActivityVolumeAndDurationKPI")
		If $$$ISERR(tSC) && pVerbose Do $system.OBJ.DisplayError(tSC)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

ClassMethod namespaceProductionType() As %String [ Internal ]
{
	Quit $Case($SYSTEM.Version.GetISCProduct(),
				4:$$$Text("Interoperability"),
				3:$$$Text("Interoperability") /* Within HS context */,
				2:$$$Text("Ensemble"),
				:$$$Text("Interoperability"))
}

ClassMethod technologyType() As %String [ Internal ]
{
	Quit $Case($SYSTEM.Version.GetISCProduct(),
				4:$$$Text("Interoperability"),
				3:$$$Text("HealthShare"),
				2:$$$Text("Ensemble"),
				:$$$Text("Interoperability"))
}

/// Private method to load localized messages into enslib.<br>
/// This will be removed when building of the kit includes loading
/// messages to enslib.
ClassMethod loadENSLIBMessages(pEnsLibRW As %Boolean = 0, pEnsLibDir As %String = "", pVerbose = 0) As %Status [ Internal, Private ]
{

	/*
		Check if we are in a container marked as "IsDeployed"
			This means that enslib directory is inside the container
			and ought to be marked read only at the file system.
	*/
	If $SYSTEM.Container.IsDeployed() Return $$$OK

	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		// IRISLIB must be read/write otherwise loadMessages fails with a <PROTECT> error
		#dim tIRISLibDir = $Extract($Get(^%SYS("DBRefByName",$$$UCFILENAME_"LIB")),3,*)
		If tIRISLibDir = "" {
			Set tIRISLibDir = ##class(%File).SubDirectoryName($SYSTEM.Util.InstallDirectory(),"mgr")
			Set tIRISLibDir = ##class(%File).SubDirectoryName(tIRISLibDir,$$$LCFILENAME_"lib")
		}

		#dim tIRISLibRW
		Set tSC = ..getDBRWFlag(tIRISLibDir,.tIRISLibRW)
		If $$$ISOK(tSC) {
			If 'tIRISLibRW {
				$$$REPORT(6,"- Marking IRISLIB as ReadOnly=0 (was previously ReadOnly="_'tIRISLibRW_")")
				Set tSC = ..setDBRWFlag(tIRISLibDir,1,10)
				Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
			}
		} Else {
			Do $system.OBJ.DisplayError(tSC)
			Set tIRISLibRW = 0
		}

		If 'pEnsLibRW {
			$$$REPORT(6,"- Marking ENSLIB as ReadOnly=0 (was previously ReadOnly="_'pEnsLibRW_")")
			Set tSC = ..setDBRWFlag(pEnsLibDir,1,10)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}

		If $$$ISOK(tSC) {
			// Load localized messages into database ENSLIB
			$$$REPORT(6,"- Loading localized messages into database ENSLIB")
			Set tSC = ..loadMessages(..GetENSLIB(1),pVerbose)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}

		Set $namespace = "%SYS"

		// Set irislib back to read only if it was read only at beginning
		If 'tIRISLibRW {
			$$$REPORT(6,"- Setting IRISLIB back to ReadOnly="_('tIRISLibRW))
			Set tSC = ..setDBRWFlag(tIRISLibDir,tIRISLibRW,10)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}

		// Set ENSLIB back to Read Only if Read Only at start of Initialization
		If 'pEnsLibRW {
			$$$REPORT(6,"- Setting ENSLIB back to ReadOnly=1")
			Set tSC = ..setDBRWFlag(..GetENSLIB(0),0,10)
			Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Mechanism to check if the Interoperability framework is
/// being started up - OnSystemStartup()
/// Does not know if OnSystemStartup() has not been invoked
/// yet.
ClassMethod SystemStartupInProgress() As %Boolean [ Internal ]
{
	Try {
		Lock +$$$EnsStartupGlobal:1
		/*	If failed to get the lock
			then system startup in progress
		*/
		Set tInProgress = '$Test
		If 'tInProgress Lock -$$$EnsStartupGlobal
	} Catch {
		/* 	Unexpected Protect Error likely reason
			for being here.
			Code suggests we cannot get
			here if tInProgress has been
			set but use guard in case.
		*/
		Set:'$Data(tInProgress) tInProgress = 0
	}
	Return tInProgress
}

}
