/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.Ensemble [ Abstract, Final, System = 4 ]
{

/// Secure wrapper for the StartProduction API in <class>Ens.Director</class>.
ClassMethod StartProduction(pProductionName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..BasicChecks("%Ens_ProductionRun:USE")
		If $$$ISERR(tSC) Quit
		New $ROLES
		If '$system.Security.Login("_Ensemble") {
			Set tSC = ##class(Ens.Util.Error).EnsError($this,"StartProduction","<Ens>ErrNoEnsembleManager")
		} Else {
			Set tSC = ##class(Ens.Director).StartProduction(.pProductionName)
		}
	}
	Catch ex {
		Set tSC = ##class(Ens.Util.Error).ExceptionStatus()
	}
	Quit tSC
}

/// Secure wrapper for the UpdateProduction API in <class>Ens.Director</class>.
ClassMethod UpdateProduction(pTimeout As %Numeric = 10, pForce As %Boolean = 0, pCalledByScheduleHandler As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	
	Try {
		Set tSC = ..BasicChecks("%Ens_ProductionRun:USE,%Ens_ConfigItemRun:USE")
		If $$$ISERR(tSC) Quit
		New $ROLES
		If '$system.Security.Login("_Ensemble") {
			Set tSC = ##class(Ens.Util.Error).EnsError($this,"UpdateProduction","<Ens>ErrNoEnsembleManager")
		} Else {
			Set tSC = ##class(Ens.Director).UpdateProduction(pTimeout,pForce,pCalledByScheduleHandler)
		}
	}
	Catch ex {
		Set tSC = ##class(Ens.Util.Error).ExceptionStatus()
	}
	Quit tSC
}

/// Secure wrapper for the StopProduction API in <class>Ens.Director</class>.
ClassMethod StopProduction(pTimeout As %Numeric = 10, pForce As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	
	Try {
		Set tSC = ..BasicChecks("%Ens_ProductionRun:USE")
		If $$$ISERR(tSC) Quit
		New $ROLES
		If '$system.Security.Login("_Ensemble") {
			Set tSC = ##class(Ens.Util.Error).EnsError($this,"StopProduction","<Ens>ErrNoEnsembleManager")
		} Else {
			Set tSC = ##class(Ens.Director).StopProduction(pTimeout, pForce)
		}
	}
	Catch ex {
		Set tSC = ##class(Ens.Util.Error).ExceptionStatus()
	}
	Quit tSC
}

/// Method to get the status of productions in all known production-enabled namespaces on this system.<br>
/// Note that data is NOT retrieved from remote databases. <br>
/// This list will not include namespaces if the default global database for the namespace is not mounted.<br>
/// The output status array is subscripted by namespace and with a value for each namespace that is a $List with 5 components:
/// <ol><li>Production Name of last used Production if any</li>
/// <li>Localized Status text</li>
/// <li>1 if the Production is Running, Stopped or Suspended, 0 otherwise, indicating 'not known to be OK'</li>
/// <li>'HS' if the namespace is HealthShare enabled, otherwise empty</li>
/// <li>The numeric state value representing the production's status</li></ol>
ClassMethod GetStatusAll(Output nsStatus) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Try {
		Kill nsStatus
		If '##class(%Library.EnsembleMgr).IsEnsembleInstalled() {
			Quit
		}
		Set tStatus = ..BasicChecks("%Ens_Portal:USE",0,0)
		If $$$ISERR(tStatus) Quit
		Merge tNspList = ^%SYS("Ensemble","InstalledNamespace")
		/* Get list of all namespaces including remote but do not connect */
		Do List^%SYS.NAMESPACE(.tNspList,4,1,1,1)
		$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
		Set tInitNS = $namespace
		Set ns = ""
		#dim tRemote
		For {
			Set ns = $order(tNspList(ns),1,tNspInfo)
			Quit:(ns = "")
			#; If Remote then check if ^Ens.Configuration global is local and DB accessible
			Set tRemote = 0
			If $ListGet(tNspInfo,2) {
				Set tRemote = 1
				Try {
					#dim tDestDir = ##class(%SYS.Namespace).GetGlobalDest(ns,"^Ens.Configuration","""csp"",""LastProduction""")
					If $piece(tDestDir,"^",1) '= "" { // Don't fetch data for remote databases
						Continue
					}
					#dim tDBStatus
					Do GetDatabaseStatus^%SYS.DATABASE($piece(tDestDir,"^",2),.tDBStatus)
					If tDBStatus'=1 Continue
				} Catch {
					Continue
				}
			} ElseIf '$ListGet(tNspInfo) {
				#; DB not available
				Continue
			}

			Set tProd = $get(^|ns|Ens.Configuration("csp","LastProduction"))
			If (tProd '= "") && $get(^|ns|Ens.MessageHeaderD) {
				Try {
					Set $namespace = ns
					If '##class(%Library.EnsembleMgr).IsEnsembleNamespace() Continue
					Kill tState
					Set tStatus1 = ##class(Ens.Director).GetProductionStatus(.tCurrProd,.tState,0)
					If '$system.Status.Equals(tStatus1, "<Ens>ErrCanNotAcquireRuntimeLock") {
						Set tStatus = $$$ADDSC(tStatus, tStatus1)
					}
					If '$data(tState) { Set tState = 0 }
				}
				Catch ex {
					Set tState = 0
					If 'tRemote || (ex.Name'="<DIRECTORY>") {
						Set tStatus1 = ex.AsStatus()
						Set tStatus = $$$ADDSC(tStatus, tStatus1)
					} Else {
						#; Main DB is remote but Ens.Configuration global is local and remote not accessible (DIRECTORY ERROR). 
						#; Do not remove from list so can still see. Remove would be: Kill tNspList(ns)
						Continue
					}
				}
				Set tStateText = ##class(Ens.Config.Production).ProductionStateToText(tState)
				Set nsStatus(ns) = $listbuild(tProd, tStateText, $case($zabs(tState), 1:1, 2:1, 3:1, :0), $select($data(^%SYS("HealthShare","Instances",ns)):"HS",1:""), tState)
			}
		}
		
		// Now check ^%SYS("Ensemble","RunningNamespace")
		Set ns = ""
		For {
			Set ns = $order(^%SYS("Ensemble","RunningNamespace",ns))
			Quit:(ns = "")
			If $data(tNspList(ns))&&'$data(nsStatus(ns)) { //Only show if allowed to see.
				Set nsStatus(ns) = $listbuild("", ##class(Ens.Config.Production).ProductionStateToText(0), 0, $select($data(^%SYS("HealthShare","Instances",ns)):"HS",1:""), 0)
			}
		}
	}
	Catch ex {
		Set tStatus1 = ex.AsStatus()
		Set tStatus = $$$ADDSC(tStatus, tStatus1)
	}
	If $data(tInitNS)#10 && ($namespace '= tInitNS) { // restore user to original namespace before $roles is reset
		Set $namespace = tInitNS
	}
	Quit tStatus
}

/// Wrapper around the SYS.EnsMetrics::GetMainMetrics() API to ensure that all users with
/// USE permissions on %Ens_Dashboard can get this information even if they aren't permitted to
/// directly run code in the system database.
ClassMethod GetEnsMetrics(pID As %String, pCount As %Integer, Output pValues, Output pStatus, Output pMsg, pInterval As %Numeric = 10) As %Status
{
		Set tSC = $$$OK
		Try {
			Set tSC = ..BasicChecks("%Ens_Dashboard:USE",0,0)
			If $$$ISERR(tSC) Quit
			If $namespace '= "%SYS" {
				Set tSC = $$$ERROR($$$GeneralError,"Must be in %SYS")
				Quit
			}
			$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
			Set tSC = ##class(SYS.EnsMetrics).GetMainMetrics(pID,pCount,.pValues,.pStatus,.pMsg,pInterval)
		}
		Catch ex {
			Set tSC = ex.AsStatus()
		}
		Quit tSC
}

/// Wrapper around the Ens.Util.Documentation::CreateDoc() API to ensure that users have sufficient privileges to
/// add the resulting material to the documentation.<br>
/// The parameter <parameter>PDFRenderer</parameter> is deprecated and is ignored.<br>
/// The parameter <parameter>pAllSettings</parameter> defaults to 0 but if set to 1
/// all settings including default values for a host item will be included.<br> 
/// 
ClassMethod CreateDocumentation(pProduction As %String = "", pIntro As %Boolean = 1, pFormat As %String, Output LogFileName As %String, Output URL As %String, Output BookName As %String, PDFFileName As %String, PDFRenderer As %String, ByRef Params As %String, pAllSettings As %Boolean = 0) As %Status
{
		Set tSC = $$$OK
		Try {
			Set tSC = ..BasicChecks("%Ens_ProductionDocumentation:USE",0,1)
			If $$$ISERR(tSC) Quit
			Kill PDFRenderer
			$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
			Set tSC = ##class(Ens.Util.Documentation).CreateDoc(pProduction, pIntro, .pFormat, .LogFileName, .URL, .BookName, .PDFFileName, .PDFRenderer,.Params, pAllSettings)
		}
		Catch ex {
			Set tSC = ex.AsStatus()
		}
		Quit tSC
}

ClassMethod GlobalInMirroredDB(pGlobal As %String = "", Output pMirrored As %Boolean) As %Status
{
	Set tSC = $$$OK
	Set pMirrored = 0
	Try {
		New $namespace
		Set tSC = ..BasicChecks("",0,1)
		If $$$ISERR(tSC) Quit
		#; Only allow Interoperability globals to start with
		If (pGlobal '= "") {
			Set tFirstFour = $zconvert($extract(pGlobal,1,4),"U")
			If (tFirstFour '= "^ENS") {
				Set tSC = $$$ERROR($$$GeneralError,"Non-Interoperability global '"_pGlobal_"' not supported.")
				Quit
			}
		}
		If '$system.Mirror.IsMember() {
			Set pMirrored = 0
			Quit
		}
		$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
		Set tGlobalRef = $select(pGlobal = "": "^", 1: pGlobal)
		Set tDBRef = ##class(%SYS.Namespace).GetGlobalDest($namespace,tGlobalRef)
		If ($piece(tDBRef,"^",1) '= "") {
			#; The database is remote. Assume not in a mirror.
			Set pMirrored = 0
			Quit
		}
		Set $namespace = "%SYS"
		Set tDBDir = $piece(tDBRef,"^",2)
		Set tDB = ##class(SYS.Database).%OpenId(tDBDir,,.tSC)
		If $$$ISERR(tSC) Quit
		Set pMirrored = (tDB.Mirrored || tDB.MirrorNoWrite || tDB.InActiveMirror)
		#; Kill tDB before stack gets popped
		Kill tDB
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Common method to ensure that the public methods of this class are correctly invoked.
ClassMethod BasicChecks(pResources As %String = "", pCheckLicense As %Boolean = 1, pCheckNamespace As %Boolean = 1) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Try {
		Set tIsEnsNamespace = ##class(%Library.EnsembleMgr).IsEnsembleNamespace()
		If pCheckNamespace && ('tIsEnsNamespace) {
			Set tSC = $$$ERROR($$$GeneralError,"Must be invoked from an production-enabled namespace")
			Quit
		}
		
		#; The resource checks can be skipped if the user has the %All role
		If (pResources '= "") && '$$$IOwnAllRole {
			Set tCanUse = 0
			For i=1:1:$length(pResources,",") {
				Set tPair = $piece(pResources,",",i)
				Set tResource = $piece(tPair,":",1)
				If tResource = "" Continue
				Set tPermission = $piece(tPair,":",2)
				If tPermission = "" Set tPermission = "USE"
				If $system.Security.Check(tResource, tPermission) {
					Set tCanUse = 1
					Quit
				}
			}
			If 'tCanUse {
				Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
				Quit
			}
		}
		If pCheckLicense && ($system.License.GetFeature(1) = 0) {
			If tIsEnsNamespace {
				Set tSC=##class(Ens.Util.Error).EnsError($this,"StartProduction","<Ens>ErrNoEnsembleLicense")
			}
			Else {
				Set tSC=$$$ERROR($$$GeneralError,"Not licensed for "_##class(%Library.EnsembleMgr).namespaceProductionType())
			}
			Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Correctly determine the expanded Interoperability manager username (used internallly and not for login)
/// if the system is using multiple domains.
/// If multiple domains are in use, then the Interoperability manager username should be present in the default domain.
ClassMethod EnsembleUsername() As %String
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	Set tSuffix = ""
	If $$$SecuritySystemExists($$$SystemSecurityName,tSecuritySettings) && $$$GetSecuritySystemSecurityDomains(tSecuritySettings) {
		Set tDefDomain = $$$GetSecuritySystemDefaultSecurityDomain(tSecuritySettings)
		If tDefDomain '= "" Set tSuffix = "@"_tDefDomain
	}
	Quit "_Ensemble"_tSuffix
}

/// This method is used by the portal page EnsPortal.ManagedAlertViewer<br><br>
/// It returns a list of users who are members of the %EnsRole_AlertManager, 
/// %EnsRole_AlertOperator or %EnsRole_Alert roles.<br>
/// If the role %EnsRole_Administrator has USE privilege on the %Ens_AlertAdministration 
/// resource then users of the role %EnsRole_Administrator will also be listed. <br>
/// Users with %All role will not be listed unless they are explicitly members of 
/// one of the roles previously mentioned.<br>
/// The default is to list  all the users in the instance. Pass the namespace in the 
/// second parameter to limit the list to the user with write access to the Ens.Alerting.ManagedAlert 
/// data in a specific namespace.<br>
/// A user must be permitted to edit alerts to call this API.
ClassMethod ListAlertingUsers(Output pUsers As %String, pLimitToNamespace As %String = "") As %Status
{
	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Set tStatus = ..BasicChecks("%Ens_Alerts:WRITE",0)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..findAlertMembers(.pUsers,pLimitToNamespace)

	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}

	Quit tStatus
}

ClassMethod findAlertMembers(Output pUsers, pLimitToNamespace As %String = "") As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tAlertRoles
	#dim tAdminRS

	Try {

		Kill pUsers
		$$$AddAllRoleTemporaryInTry
		New $namespace
		Set $namespace = "%SYS"

		Set tAlertRoles("%EnsRole_AlertOperator") = ""
		Set tAlertRoles("%EnsRole_Alert") = ""
		Set tAlertRoles("%EnsRole_AlertAdministrator") = ""

		#; Check whether %EnsRole_Administrator has USE permissions on %Ens_AlertAdministration; if so, include users from this role
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode = 2
		Set tSC = tStatement.%Prepare("SELECT Permission FROM Security.Resource WHERE TheRole = LOWER('%EnsRole_Administrator') AND Name = '%Ens_AlertAdministration'")
		If $$$ISERR(tSC) Quit
		Set tAdminRS = tStatement.%Execute()
		If tAdminRS.%Next() && (tAdminRS.Permission [ "U") {
			Set tAlertRoles("%EnsRole_Administrator") = ""
		}
		Kill tStatement

		Set tSC = ..findUserMembers(.tAlertRoles, .pUsers)

		#; Limit the list to those that have write access to global in this namespace.
		If pLimitToNamespace '= "" {
			Do ..filterUsersOnGlobalAccess(.pUsers, pLimitToNamespace, "Ens.Alerting.ManagedAlertD",,"WRITE")
		}

	} Catch ex {Set tSC = ex.AsStatus()}

	#; Ensure we kill the result sets before we pop the namespace
	Kill tAdminRS
	Quit tSC
}

/// Internal private method to find all users in ROLE hierarchy for array of roles given by pRoles
ClassMethod findUserMembers(ByRef pRoles, Output pUsers) As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#;Make a copy since we are going to manipulate
		#dim tRolesToWalk
		Merge tRolesToWalk = pRoles

		#dim tRolesAleadyExamined, tNewRoles
		#dim tOneRole = $Order(tRolesToWalk(""))
		While tOneRole '="" {

			Set tSC = ..findMembers(tOneRole, .pUsers, .tRolesAleadyExamined, .tNewRoles)

			#; findMembers cannot be recursive due to %Library.SQLCatalogPriv:SQLRoleUser
			Set tOneRole = $Order(tRolesToWalk(tOneRole))
			If tOneRole = "" {
				Kill tRolesToWalk
				#; tNewRoles is being added to and pruned in findMembers
				Merge tRolesToWalk = tNewRoles
				Set tOneRole = $Order(tNewRoles(""))
			}

		}
	} Catch ex {Set tSC = ex.AsStatus()}

	Quit tSC
}

/// Find User and Role members for role pRole. Called by findUserMembers
ClassMethod findMembers(pRole As %String, ByRef pUsers, ByRef pRolesAleadyExamined, ByRef pNewRolesToExamine) As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tRS
	#dim tName
 
	Try {

		Set pRolesAleadyExamined(pRole)=""

		#; Might not exist
		Kill pNewRolesToExamine(pRole)

		#;Cannot recurse this query
		Set tRS = ##class(%ResultSet).%New("%Library.SQLCatalogPriv:SQLRoleUser")
		Set tSC = tRS.Execute(pRole)
		If $$$ISERR(tSC) Quit

		While tRS.Next() {
		 	Set tName = tRS.Get("NAME")
			If (tRS.Get("USER") = "USER") {
				#; May duplicate sets but overwrite OK
				Set pUsers(tName)=""
			} ElseIf (tRS.Get("USER") = "ROLE") {
				If '$Data(pRolesAleadyExamined(tName))#2 Set pNewRolesToExamine(tName)=""
			}
		}

	} Catch ex { Set tSC=ex.AsStatus()}

	#; Ensure we kill the result sets incase we will pop the namespace
	Kill tRS
	Quit tSC
}

/// Internal helper method to identify if user has access to the global
/// Error handling to be trapped by caller.
ClassMethod filterUsersOnGlobalAccess(ByRef pUsers As %String, pNamespace As %String = {$NAMESPACE}, pGlobal As %String = "", pSubscript As %String = "", pAccessMode As %String = "READ") As %Boolean [ Internal, Private ]
{

	#dim tImpliedNamespace, tImpliedNamespaceInfo, tResource As %String

	Set tImpliedNamespace = ##class(%SYS.Namespace).GetGlobalDest(pNamespace,pGlobal,pSubscript)
	If $Length(tImpliedNamespace,"^")<2 Set tImpliedNamespace="^"_tImpliedNamespace
	If $Length(tImpliedNamespace,"^")<3 Set tImpliedNamespace="^"_tImpliedNamespace

	Kill tImpliedNamespaceInfo
	Do GetNSInfo^%SYS.NAMESPACE(tImpliedNamespace, .tImpliedNamespaceInfo)
	Set tResource = $Get(tImpliedNamespaceInfo("Resource"))
	
	#dim tOneUser = $Order(pUsers(""))

	While tOneUser'="" {
		If '$SYSTEM.Security.CheckUserPermission(tOneUser,tResource,pAccessMode) {
			Kill pUsers(tOneUser)
		}
		Set tOneUser = $Order(pUsers(tOneUser))
	}
	#;clean up after CheckUserPermission call.
	Kill %sqlcontext
}

/// Wrapper for getting secondary data. User needs Read access to the DB for 'Password'. Only support Password.
ClassMethod SecondaryGet(pKey As %String = "", pProperty As %String = "", ByRef pSC As %Status) As %String [ Internal ]
{
	Set pSC = $$$OK, tValue = ""
	Try {
		Quit:(pProperty'="Password")
		Set tValue = $G(^Ens.SecondaryData.Password(pKey))
	}
	Catch ex {
		Set pSC = ##class(Ens.Util.Error).ExceptionStatus(),tValue=""
	}
	Quit tValue
}

/// Secure wrapper for writing secondary data. Only support Password.
ClassMethod SecondarySet(pValue As %String = "", pKey As %String = "", pProperty As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Quit:(pKey="") tSC
	Quit:(pProperty'="Password") tSC
	Try {
		Set tResourceRequired = "%Ens_Credentials:W"
		Set tSC = ..BasicChecks(tResourceRequired,0,0)
		If $$$ISERR(tSC) Quit
		$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
		Set ^Ens.SecondaryData.Password(pKey) = pValue
	}
	Catch ex {
		Set tSC = ##class(Ens.Util.Error).ExceptionStatus()
	}
	Quit tSC
}

/// Secure wrapper for deleting secondary data.  Only support Password.
ClassMethod SecondaryDelete(pKey As %String = "", pProperty As %String = "") As %Status [ Internal ]
{
	Set tSC=$$$OK
	Quit:(pKey="") tSC
	Quit:(pProperty'="Password") tSC
	Try {
		Set tResourceRequired = "%Ens_Credentials:W"
		Set tSC = ..BasicChecks(tResourceRequired)
		If $$$ISERR(tSC) Quit
		$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
		Kill ^Ens.SecondaryData.Password(pKey)
	} Catch ex {
		Set tSC = ##class(Ens.Util.Error).ExceptionStatus()
	}	
	Quit tSC
}

/// Method used by PEX Components Registration to bounce the server if necessary for ensuring the correct file is used
/// User might not have %Admin_Manage and %DB_IRISSYS privileges
/// Instead require WRITE priv on the %Ens_Code resource in order to gain elevated privileges.
ClassMethod BounceExternalLanguageServer(pServer As %String = "") As %Status
{
	#dim ex As %Exception.AbstractException
	#dim tSC As %Status = $$$OK
	
	Try {		
		Set tSC = ..BasicChecks("%Ens_Code:WRITE",0)
		If $$$ISERR(tSC) Quit
		
		Try {
			Set tSC = ..doELSBounce(pServer)
		} Catch {
			Set tSC = $$$ERROR($$$GeneralError,"Failed to bounce the External Language Server")
		}
		Quit:$$$ISERR(tSC)
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod doELSBounce(pServer As %String = "") As %Status [ Internal, Private ]
{
	#dim ex As %Exception.AbstractException
	#dim tStopped,tRestarted As %Boolean = 0
	#dim tSC As %Status = $$$OK

	Try {

		#; Need to add %Admin_Manage:USE and %DB_IRISSYS
		#dim tTempRoleToAdd = "%Manager"
		#; Since this is a %SYS routine it has access to the SYS global.
		If $Data($$$SecurityGlobalRoles(tTempRoleToAdd)){
			New $roles
			Set $roles=$roles_","_tTempRoleToAdd
		} /* else we will proceed and error out returning the lack of privilege */
		
		New $Namespace
		Set $Namespace = "%SYS"
		
		Set tStopped = $System.external.stopServer(pServer)
		If tStopped {
			Set tRestarted = $System.external.startServer(pServer)
		}
		#; tRestarted will still be 0 unless stopped and started successfully
		If 'tRestarted {
			Set tSC = $$$ERROR($$$GeneralError,"Failed to bounce the External Language Server")
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Method used by Context Search to get list of External Language Servers
/// User might not have SQL privs on the Config.Gateways::ListShort query
/// Instead require WRITE priv on the %Ens_ProductionConfig resource in order to gain elevated privileges.
ClassMethod GetExternalLanguageServers(ByRef pServers) As %Status
{
	#dim ex As %Exception.AbstractException
	#dim tSC As %Status = $$$OK
	
	Try {
		Kill pServers
		
		Set tSC = ..BasicChecks("%Ens_ProductionConfig:WRITE",0)
		If $$$ISERR(tSC) Quit
		
		Try {
			Set tSC = ..findExternalLanguageServers(.pServers)
		} Catch {
			Set tSC = $$$ERROR($$$GeneralError,"Failed execution of External Language Server query")
		}
		Quit:$$$ISERR(tSC)
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod findExternalLanguageServers(ByRef pServers) As %Status [ Internal, Private ]
{
	#dim ex As %Exception.AbstractException
	#dim tSC As %Status = $$$OK

	Try {

		#dim tTempRoleToAdd = "%DB_IRISSYS"
		#; Since this is a %SYS routine it has access to the SYS global.
		If $Data($$$SecurityGlobalRoles(tTempRoleToAdd)){
			New $roles
			Set $roles=$roles_","_tTempRoleToAdd
		} /* else we will proceed and error out returning the lack of privilege */
		
		New $Namespace
		Set $Namespace = "%SYS"
		
		Set tResultSet = ##class(%ResultSet).%New("Config.Gateways:ListShort")
		Set tSC = tResultSet.%Execute()
		
		While tResultSet.%Next(.tSC) {
			Quit:$$$ISERR(tSC)

			Set tType = tResultSet.%Get("Type")
			Set tName = tResultSet.%Get("Name")
			
			Set pServers(tName) = tType
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Method used by DTL Test page that requires de-serialization of the test input data
/// User might not have SQL privs on the %Dictionary.ParameterDefinition table
/// If the User does not have SQL Select privs on %Dictionary.ParameterDefinition table then user
/// requires USE priv on the %Ens_DTLTest resource in order to gain elevated privileges.
ClassMethod GetMapParent(pInputClass As %String, pIsBatch As %Boolean = 0, Output pSC As %Status = {$$$OK}) As %Status
{
	#dim ex As %Exception.AbstractException
	#dim tParent = ""
	#dim tEscalate = 0

	Try {

		If '$system.SQL.CheckPriv($username,"1,%Dictionary.ParameterDefinition","s") {

			Set pSC = ..BasicChecks("%Ens_DTLTest:USE",0)
			If $$$ISERR(pSC) Quit

			Set tEscalate = 1

		}

		Set tParent = ..findMapParent(pInputClass,pIsBatch,tEscalate,.pSC)

	} Catch ex {

		Set pSC = ex.AsStatus()

	}

	Return tParent
}

ClassMethod findMapParent(pInputClass As %String, pIsBatch As %Boolean = 0, pEscalate As %Boolean = 0, Output pSC As %Status = {$$$OK}) As %Status [ Internal, Private ]
{
	#dim ex As %Exception.AbstractException
	#dim tParent = ""

	Try {

		If pEscalate {
			#dim tTempRoleToAdd = "%EnsRole_TempSQLDict"
			#; Since this is a %SYS routine it has access to the SYS global.
			If $Data($$$SecurityGlobalRoles(tTempRoleToAdd)){
				New $roles
				Set $roles=$roles_","_tTempRoleToAdd
			} /* else we will proceed and error out returning the lack of privilege */
		}

		#dim tStatement = ##class(%SQL.Statement).%New()
		#dim tSQL = "SELECT parent from %Dictionary.ParameterDefinition WHERE name = ? AND _default = ?"
		Set pSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(pSC) Quit

		#dim tName = $Select(pIsBatch:"BATCHCLASS", 1:"OBJECTNAME")
		#dim tResult = tStatement.%Execute(tName, pInputClass)
		If 'tResult.%Next() Quit

		Set tParent = tResult.parent

	} Catch ex {

		Set pSC = ex.AsStatus()

	}

	Return tParent
}

/// Method used by Ens.Director::CreateBusinessService 
/// to aid checking if process originated with a TCP connection so
/// that INTERRUPTs and DISCONNECT detects can be disabled.
/// Checks the current process devices and returns the first one
/// if it is a TCP device. Otherwise it returns empty string.
/// 
ClassMethod GetFirstDeviceIfTCP(pSC As %Status = {$$$OK}) As %String [ Internal ]
{
	#dim ex As %Exception.AbstractException
	#dim tFirstDeviceIfTCP = ""
	Try {
		/*	Obtain open devices for current job
			limit to examining the first to see if TCP
		*/
		Set tOpenDevices=$Translate($List($View(-1,-3,2),3),"*","")
		If ($E(tOpenDevices,1,5)="|TCP|") {
			Set tFirstDeviceIfTCP=$Piece(tOpenDevices,",")
		}
	} Catch ex {
		Set pSC = ex.AsStatus()
	}
	Return tFirstDeviceIfTCP
}

/// Internal method to set SAM Sensors for Interoperability Interface metrics
ClassMethod SetSAMSensorsForInteropInterfaces(pSAMSensors As SYS.Monitor.SAM.Sensors, pStart As %TimeStamp = "", pEnd As %TimeStamp = "", pNamespace As %String = "") As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSQL = "SELECT Type, Namespace, Protocol, ""Count"", Active FROM SYS_Monitor_Interop_Interface.Utils_InteropInterfaces(?,?,?)"
		Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL,pStart,pEnd,pNamespace)
		If ''tRS.%SQLCODE {
			Set tSC = $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
			Quit
		}
		While tRS.%Next() {
			Set tType = tRS.%Get("Type")
			Set tNamespace = tRS.%Get("Namespace")
			Set tProtocol = tRS.%Get("Protocol")
			Set tCount = tRS.%Get("Count")
			Set tActive = tRS.%Get("Active")
			Set tSensorName = $ZStrip("Interop"_$S(tActive:"Active",1:"")_tType_"Interfaces","*W")
			Kill tLabels
			If ""=(tNamespace_tProtocol) {
				Set tSensorName = tSensorName_"Total"
				Do pSAMSensors.SetSensor(tSensorName,tCount)
			} ElseIf ""=tNamespace {
				Set tLabels("protocol") = tProtocol
				Do pSAMSensors.SetSensorLabels(tSensorName,tCount,.tLabels)
			} ElseIf ""=tProtocol {
				Set tLabels("id") = tNamespace
				Do pSAMSensors.SetSensorLabels(tSensorName,tCount,.tLabels)
			} Else {
				Set tLabels("id") = tNamespace
				Set tLabels("protocol") = tProtocol
				Do pSAMSensors.SetSensorLabels(tSensorName,tCount,.tLabels)
			}
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to set SAM Sensors for Interoperability Database Impact metrics
ClassMethod SetSAMSensorsForInteropCurrentDatabaseImpact(pSAMSensors As SYS.Monitor.SAM.Sensors, pStart As %TimeStamp = "", pEnd As %TimeStamp = "", pDatabase As %String = "") As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		Set tStart = $SELECT(pStart="":$ZDATETIME(0,3),1:pStart)
		Set tSC = ##class(%TimeStamp).IsValid(tStart)
		Quit:$$$ISERR(tSC)
		Set tEnd = $SELECT(pEnd="":$ZDATETIME(2980013,3),1:pEnd) //2980013 is max $H value
		Set tSC = ##class(%TimeStamp).IsValid(tEnd)
		Quit:$$$ISERR(tSC)
		Set tSQL = "SELECT Database, DataCreated FROM %SYS_Monitor_Interop_DatabaseImpact.Utils_Impact(?,?"
		Set tParams($INCREMENT(tParams)) = tStart
		Set tParams($INCREMENT(tParams)) = tEnd
		If pDatabase'="" {
			Set tSQL = tSQL _ ",?)"
			Set tParams($INCREMENT(tParams)) = pDatabase
		} Else {
			Set tSQL = tSQL _ ")"
		}
		Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL,tParams...)
		If ''tRS.%SQLCODE {
			Set tSC = $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
			Quit
		}
		While tRS.%Next(.tSC) {
			Set tDataCreated = tRS.%Get("DataCreated")
			Set tDatabase = tRS.%Get("Database")
			Set tSensorName = "InteropDatabaseImpact"
			Kill tLabels
			Set tLabels("id") = tDatabase
			Do pSAMSensors.SetSensorLabels(tSensorName,tDataCreated,.tLabels)
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to set SAM Sensors for Interoperability Database Impact metrics
ClassMethod SetSAMSensorsForInteropHistoricalDatabaseImpact(pSAMSensors As SYS.Monitor.SAM.Sensors, pStartMonth As %String = "", pEndMonth As %String = "", pDatabase As %String = "") As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		Set tStartMonth = $SELECT(pStartMonth="":$PIECE($ZDATETIME(0,3),"-",1,2),1:pStartMonth)
		If (tStartMonth'?4N1"-"2N) {
			Set tSC = $$$ERROR($$$InteropInvalidMonth,tStartMonth)
			Quit
		}
		Set tEndMonth = $SELECT(pEndMonth="":$PIECE($ZDATETIME(2980013,3),"-",1,2),1:pEndMonth) //2980013 is max $H value
		If (tEndMonth'?4N1"-"2N) {
			Set tSC = $$$ERROR($$$InteropInvalidMonth,tEndMonth)
			Quit
		}
		Set tSQL = "SELECT Month, Database, Total FROM SYS_Monitor_Interop.ConsolidatedMetrics_DatabaseImpact(?,?"
		Set tParams($INCREMENT(tParams)) = tStartMonth
		Set tParams($INCREMENT(tParams)) = tEndMonth
		If pDatabase'="" {
			Set tSQL = tSQL _ ",?)"
			Set tParams($INCREMENT(tParams)) = pDatabase
		} Else {
			Set tSQL = tSQL _ ")"
		}
		Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL,tParams...)
		If ''tRS.%SQLCODE {
			Set tSC = $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
			Quit
		}
		While tRS.%Next(.tSC) {
			Set tTotal = tRS.%Get("Total")
			Set tDatabase = tRS.%Get("Database")
			Set tMonth = tRS.%Get("Month")
			Set tSensorName = "InteropDatabaseImpact"
			Kill tLabels
			Set tLabels("id") = tDatabase
			Set tLabels("month") = tMonth
			Do pSAMSensors.SetSensorLabels(tSensorName,tTotal,.tLabels)
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to set SAM Sensors for Interoperability Interfaces metrics
ClassMethod SetSAMSensorsForInteropHistoricalInterfaces(pSAMSensors As SYS.Monitor.SAM.Sensors, pStartMonth As %String = "", pEndMonth As %String = "", pNamespace As %String = "") As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		Set tStartMonth = $SELECT(pStartMonth="":$PIECE($ZDATETIME(0,3),"-",1,2),1:pStartMonth)
		If (tStartMonth'?4N1"-"2N) {
			Set tSC = $$$ERROR($$$InteropInvalidMonth,tStartMonth)
			Quit
		}
		Set tEndMonth = $SELECT(pEndMonth="":$PIECE($ZDATETIME(2980013,3),"-",1,2),1:pEndMonth) //2980013 is max $H value
		If (tEndMonth'?4N1"-"2N) {
			Set tSC = $$$ERROR($$$InteropInvalidMonth,tEndMonth)
			Quit
		}
		Set tSQL = "SELECT Namespace, InterfaceType, Total, Month, Protocol FROM SYS_Monitor_Interop.ConsolidatedMetrics_Interfaces(?,?"
		Set tParams($INCREMENT(tParams)) = tStartMonth
		Set tParams($INCREMENT(tParams)) = tEndMonth
		If pNamespace'="" {
			Set tSQL = tSQL _ ",?)"
			Set tParams($INCREMENT(tParams)) = pNamespace
		} Else {
			Set tSQL = tSQL _ ")"
		}
		Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL,tParams...)
		If ''tRS.%SQLCODE {
			Set tSC = $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
			Quit
		}
		While tRS.%Next(.tSC) {
			Set tType = tRS.%Get("InterfaceType")
			Set tNamespace = tRS.%Get("Namespace")
			Set tProtocol = tRS.%Get("Protocol")
			Set tCount = tRS.%Get("Total")
			Set tMonth = tRS.%Get("Month")
			Set tSensorName = $ZStrip("Interop"_tType_"Interfaces","*W")
			Kill tLabels
			Set tLabels("month") = tMonth
			If ""=(tNamespace_tProtocol) {
				Set tSensorName = tSensorName_"Total"
				Do pSAMSensors.SetSensorLabels(tSensorName,tCount,.tLabels)
			} ElseIf ""=tNamespace {
				Set tLabels("protocol") = tProtocol
				Do pSAMSensors.SetSensorLabels(tSensorName,tCount,.tLabels)
			} ElseIf ""=tProtocol {
				Set tLabels("id") = tNamespace
				Do pSAMSensors.SetSensorLabels(tSensorName,tCount,.tLabels)
			} Else {
				Set tLabels("id") = tNamespace
				Set tLabels("protocol") = tProtocol
				Do pSAMSensors.SetSensorLabels(tSensorName,tCount,.tLabels)
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to set SAM Sensors for Interoperability Volume metrics
ClassMethod SetSAMSensorsForInteropCurrentVolume(pSAMSensors As SYS.Monitor.SAM.Sensors, pStart As %TimeStamp = "", pEnd As %TimeStamp = "", pNamespace As %String = "") As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		Set tStart = $SELECT(pStart="":$ZDATETIME(0,3),1:pStart)
		Set tSC = ##class(%TimeStamp).IsValid(tStart)
		Quit:$$$ISERR(tSC)
		Set tEnd = $SELECT(pEnd="":$ZDATETIME(2980013,3),1:pEnd) //2980013 is max $H value
		Set tSC = ##class(%TimeStamp).IsValid(tEnd)
		Quit:$$$ISERR(tSC)
		Set tSQL = "SELECT Namespace, Type, Volume FROM %SYS_Monitor_Interop_Messages.Utils_MetricsTotalPerNamespace(?,?"
		Set tParams($INCREMENT(tParams)) = tStart
		Set tParams($INCREMENT(tParams)) = tEnd
		If pNamespace'="" {
			Set tSQL = tSQL _ ",?)"
			Set tParams($INCREMENT(tParams)) = pNamespace
		} Else {
			Set tSQL = tSQL _ ")"
		}
		Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL,tParams...)
		If ''tRS.%SQLCODE {
			Set tSC = $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
			Quit
		}
		While tRS.%Next(.tSC) {
			Set tType = tRS.%Get("Type")
			Set tVolume = tRS.%Get("Volume")
			Set tNamespace = tRS.%Get("Namespace")
			Set tSensorName = "InteropVolume"
			Kill tLabels
			Set tLabels("id") = tNamespace
			Set tLabels("type") = tType
			Do pSAMSensors.SetSensorLabels(tSensorName,tVolume,.tLabels)
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to set SAM Sensors for Interoperability Volume metrics
ClassMethod SetSAMSensorsForInteropHistoricalVolume(pSAMSensors As SYS.Monitor.SAM.Sensors, pStartMonth As %String = "", pEndMonth As %String = "", pNamespace As %String = "") As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		Set tStartMonth = $SELECT(pStartMonth="":$PIECE($ZDATETIME(0,3),"-",1,2),1:pStartMonth)
		If (tStartMonth'?4N1"-"2N) {
			Set tSC = $$$ERROR($$$InteropInvalidMonth,tStartMonth)
			Quit
		}
		Set tEndMonth = $SELECT(pEndMonth="":$PIECE($ZDATETIME(2980013,3),"-",1,2),1:pEndMonth) //2980013 is max $H value
		If (tEndMonth'?4N1"-"2N) {
			Set tSC = $$$ERROR($$$InteropInvalidMonth,tEndMonth)
			Quit
		}
		Set tSQL = "SELECT Month, Namespace, InterfaceType, Total FROM SYS_Monitor_Interop.ConsolidatedMetrics_Volume(?,?"
		Set tParams($INCREMENT(tParams)) = tStartMonth
		Set tParams($INCREMENT(tParams)) = tEndMonth
		If pNamespace'="" {
			Set tSQL = tSQL _ ",?)"
			Set tParams($INCREMENT(tParams)) = pNamespace
		} Else {
			Set tSQL = tSQL _ ")"
		}
		Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL,tParams...)
		If ''tRS.%SQLCODE {
			Set tSC = $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
			Quit
		}
		While tRS.%Next(.tSC) {
			Set tTotal = tRS.%Get("Total")
			Set tNamespace = tRS.%Get("Namespace")
			Set tMonth = tRS.%Get("Month")
			Set tInterfaceType = tRS.%Get("InterfaceType")
			Set tSensorName = "InteropVolume"
			Kill tLabels
			If tNamespace = "" {
				Set tSensorName = tSensorName_"Total"
			} Else {
				Set tLabels("id") = tNamespace
			}
			Set tLabels("month") = tMonth
			Set tLabels("type") = tInterfaceType
			Do pSAMSensors.SetSensorLabels(tSensorName,tTotal,.tLabels)
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to set SAM Sensors for Interoperability Range metrics
ClassMethod SetSAMSensorsForInteropCurrentRange(pSAMSensors As SYS.Monitor.SAM.Sensors) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		//Find the min and max timestamp from each metrics table
		Set tSQL($INCREMENT(tSQL)) = "SELECT CAST(Min(Day) as Date) as minDay, Cast(Max(Day) as Date) as maxDay FROM %SYS_Monitor_Interop.Messages"
		Set tSQL($INCREMENT(tSQL)) = "SELECT CASE WHEN Min(Activated) < Min(Deactivated)" _
		" THEN CAST(Min(Activated) as Date) ELSE CAST(Min(Deactivated) as Date) END AS minDay," _
		" CASE WHEN Max(Activated) > Max(Deactivated) THEN CAST(Max(Activated) as Date)" _
		" ELSE CAST(Max(Deactivated) as Date) END AS maxDay" _
		" FROM SYS_Monitor_Interop_Interface.Activity"
		Set tSQL($INCREMENT(tSQL)) = "SELECT CAST(Min(TimeStamp) as Date) as minDay, CAST(Max(TimeStamp) as Date) as maxDay FROM %SYS_Monitor_Interop.DatabaseImpact"
		Set start=""
		set end=""
		For i=1:1:tSQL {
			Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL(i))
			If ''tRS.%SQLCODE {
				Return $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
			}
			While tRS.%Next(.tSC) {
				If (tRS.minDay'="") && ((start="") || (start>tRS.minDay)) {
					Set start=tRS.minDay
				}
				If (tRS.maxDay'="") && ((end="") || (end<tRS.maxDay)) {
					Set end=tRS.maxDay
				}
			}
			Return:$$$ISERR(tSC) tSC
		}
		If (start="") && (end="") {
			Return $$$OK
		}
		If start'="" {
			Set tSensorName = "InteropRangeStart"
			Do pSAMSensors.SetSensor(tSensorName,$ZDATETIME(start,3))
		}
		If end'="" {
			Set tSensorName = "InteropRangeEnd"
			Do pSAMSensors.SetSensor(tSensorName,$ZDATETIME(end,3))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to set SAM Sensors for Interoperability Range metrics
ClassMethod SetSAMSensorsForInteropHistoricalRange(pSAMSensors As SYS.Monitor.SAM.Sensors) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If '$IsObject(pSAMSensors) || 'pSAMSensors.%IsA("SYS.Monitor.SAM.Sensors") {
		Quit $$$ERROR($$$GeneralError,"Invalid SAM Sensors object")
	}

	Try {
		$$$AddAllRoleTemporaryInTry
		//Find the min and max month
		Set tSQL = "SELECT Min(Month) as minMonth, Max(Month) as maxMonth FROM SYS_Monitor_Interop.ConsolidatedMetrics"
		Set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,tSQL)
		If ''tRS.%SQLCODE {
			Return $System.Error.FromSQLCode(tRS.%SQLCODE,tRS.%Message).Status
		}
		While tRS.%Next(.tSC) {
			Set start=tRS.minMonth
			Set end=tRS.maxMonth
		}
		If (start="") && (end="") {
			Return $$$OK
		}
		If start'="" {
			Set tSensorName = "InteropRangeStart"
			Do pSAMSensors.SetSensor(tSensorName,start)
		}
		If end'="" {
			Set tSensorName = "InteropRangeEnd"
			Do pSAMSensors.SetSensor(tSensorName,end)
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to create XML Schema global
/// for user with appropriate permission
ClassMethod CreateXMLSchemaGlobal() As %Status [ Internal ]
{
	#define vaSchemaGbl		^EnsEDI.XML.Schema
	#define IRISStandard	5
	Set tSC = $$$OK
	If '$D($$$vaSchemaGbl) {
		#; check appropriate permissions %Ens_EDISchema:WRITE
		If $system.Security.Check("%Ens_EDISchema","WRITE") {
			Try {
				$$$AddAllRoleTemporaryInTry
				Set tSC = ##class(%Library.GlobalEdit).Create(,$name($$$vaSchemaGbl),$$$IRISStandard)
			} Catch ex {
				Set tSC = ex.AsStatus()
			}
		} Else {
			Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
		}
	}
	Return tSC
}

}
