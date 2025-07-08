/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syConfig, %sySystem)

/// Implements all installation operations
Class %Installer.Installer Extends %RegisteredObject [ ServerOnly = 1, System = 3 ]
{

/// Variables
Property Variables As %String [ Internal, MultiDimensional, Private ];

/// InterSystems IRIS configuration object
Property Configuration As Config.Configuration [ Internal ];

/// Log level
Property LogLevel As %Integer [ InitialExpression = 0, Internal ];

/// Logger
Property Logger As %Installer.AbstractLogger [ Internal ];

/// Namespace stack
Property NSStack As %String [ Internal ];

/// Default DB resource
Parameter DEFAULTDBRESOURCE As STRING = "%DB_%DEFAULT";

/// Default installer method name
Parameter DEFAULTINSTALLERMETHODNAME As STRING = "setup";

/// Called to load and run an install from the command line
/// The pManifestSpec is the /INSTALLERMANIFEST parameter
/// The pManifestParams is the INSTALLERMANIFESTPARAMS parameter
ClassMethod InstallFromCommandLine(pManifestSpec As %String, pManifestParams As %String = "", ByRef pLogLevel, pLogger As %Installer.AbstractLogger) As %Status [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tClass As %String
		#dim tMethod As %String
		#dim tParams
		
		// Load the XML into the namespace
		Set tSC = ..LoadManifestXML(pManifestSpec,,.tClass,.tMethod)
		Quit:$$$ISERR(tSC)

		// Convert parameters
		Set tSC = ..processParamsIntoArray(pManifestParams,1,.tParams)
		Quit:$$$ISERR(tSC)
		
		// Now invoke... Only pass pLogger if it is defined, for compatibility with older manifests.
		if $d(pLogger) {
			Set tSC = $classmethod(tClass,tMethod,.tParams,.pLogLevel,,pLogger)
		} else {
			Set tSC = $classmethod(tClass,tMethod,.tParams,.pLogLevel)
		}
		Quit:$$$ISERR(tSC)
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Run %Installer.InstallFromCommandLine on the first restart after installation or upgrade
ClassMethod InstallOnFirstRestart()
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"

	#dim tManifest As %String
	#dim tParams As %String
	#dim tLogLevel As %Integer
	#dim tLogFile As %String
	
	Set tManifest=$Get(^SYS("Installer","Manifest"))
	Set tParams=$Get(^SYS("Installer","Params"))
	Set tLogLevel=$Get(^SYS("Installer","LogLevel"))
	Set tLogFile=$Get(^SYS("Installer","LogFile"))
	
	If tManifest'="" {
		$$$InfoMsg("Installing Manifest "_tManifest)
		
		#dim tLogger As %Installer.AbstractLogger
		Kill %objlasterror
		If tLogFile'="" {
			Set tLogger = ##class(%Installer.FileLogger).%New(1, tLogFile)
		} else {
			Set tLogger = ##class(%Installer.AbstractLogger).%New()
		}

		// Check for errors during log creation
		If '$IsObject(tLogger) && ($G(%objlasterror)'="") && $$$ISERR(%objlasterror) {
			Set tSC = %objlasterror
			$$$SevereError($SYSTEM.Status.GetErrorText(tSC))
			Quit tSC
		}

		Set tSC = ..InstallFromCommandLine(tManifest, tParams, tLogLevel, tLogger)
		If $$$ISERR(tSC) $$$SevereError($SYSTEM.Status.GetErrorText(tSC)) Quit tSC
		$$$InfoMsg("Manifest  "_tManifest_" installed")
	}
	
	Kill ^SYS("Installer","Manifest")
	Kill ^SYS("Installer","Params")
	Kill ^SYS("Installer","LogLevel")
	Kill ^SYS("Installer","LogFile")
	
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	$$$SevereError($SYSTEM.Status.GetErrorText(tSC))
	Goto Exit
}

/// Load a manifest XML from a file
ClassMethod LoadManifestXML(pManifestSpec As %String, pNamespace As %String = {$NAMESPACE}, ByRef pClass As %String, ByRef pMethod As %String) As %Status [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	New $NAMESPACE
	s pNamespace=$zcvt(pNamespace,"U")
	Do {
		#dim tClasses As %String
		#dim tFilename As %String
		#dim tParams
		
		// Switch namespaces if necessary
		If $NAMESPACE'=pNamespace Set $NAMESPACE=pNamespace
		
		// Convert manifest spec
		Set tSC = ..processParamsIntoArray(pManifestSpec,0,.tParams)
		Quit:$$$ISERR(tSC)
		
		Set tFilename=$G(tParams(1)),pClass=$G(tParams(2)),pMethod=$G(tParams(3),..#DEFAULTINSTALLERMETHODNAME)
		
		Set tSC = $system.OBJ.Load(tFilename,"ck",,.tClasses)
		Quit:$$$ISERR(tSC)
		
		// If the user didn't specify the class, try to figure it out from the "loaded" list
		If pClass="" {
			#dim tI As %Integer
			
			// Look for a class with a setup method
			For tI=1:1:$L(tClasses,",") {
				#dim tClass As %String
				#dim tMethodDef As %Dictionary.MethodDefinition
				
				Set tClass=$P(tClasses,",",tI)
				
				// Skip non-class items
				If $P(tClass,".",$L(tClass,"."))'="cls" Continue
				
				Set tClass=$P(tClass,".",1,$L(tClass,".")-1)
				Set tMethodDef=##class(%Dictionary.MethodDefinition).%OpenId(tClass_"||"_pMethod)
				If $IsObject(tMethodDef)&&tMethodDef.ClassMethod {
					// Found it
					Set pClass=tClass
					Quit
				}
			}
		}
		
		// Validate
		If (pClass="")||(pMethod="") {
			Set tSC = $$$ERROR($$$InstallerInvalidManifestSpecification,pManifestSpec)
			Quit
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Switch to a new namespace, saving the current one
Method PushNS(pNS As %String) [ Internal ]
{
	// Store the current namespace and switch (if needed)
	Set:..NSStack'="" ..NSStack=..NSStack_","
	Set ..NSStack = ..NSStack _ $NAMESPACE
	If pNS'="",$NAMESPACE'=pNS Set $NAMESPACE=pNS
	Quit
}

/// Revert to a previous namespace
Method PopNS() [ Internal ]
{
	#dim tNS As %String
	// Pop the previous namespace and switch (if needed)
	Set tNS = $P(..NSStack,",",$L(..NSStack,",")),..NSStack = $P(..NSStack,",",1,$L(..NSStack,",")-1)
	If tNS'="",$NAMESPACE'=tNS Set $NAMESPACE=tNS
	Quit
}

/// Check a variable
Method IsVariableDefined(pName As %String) [ CodeMode = expression, Internal ]
{
$DATA(..Variables(pName))#2
}

/// Set a variable
Method SetVariable(pName As %String, pValue As %String) [ Internal ]
{
	Do ..Log(3,"SetVariable",pName_"="_pValue)
	Set ..Variables(pName) = pValue
}

/// Delete a variable
Method DeleteVariable(pName As %String) [ Internal ]
{
	Do ..Log(3,"DeleteVariable",pName)
	Kill ..Variables(pName)
}

/// Get the value of a variable
Method GetVariable(pName As %String, Output pResult As %String, pEvaluate As %Boolean = 1) As %String [ Internal ]
{
	Quit $SELECT(pEvaluate:..Evaluate($GET(..Variables(pName))),1:$GET(..Variables(pName)))
}

/// Evaluate an expression.  Expressions are strings that support 3 flavors of string expansion:
/// <br/>
/// <li><b>${<i>variable</i>}</b>: Expands to the named variable</li>
/// <li><b>${#<i>parameter</i>}</b>: Expands to the named parameter value for the class that contains the XML</li>
/// <li><b>#{<i>expr</i>}</b>: Expands to the CoS expression (must be properly quoted)</li>
/// <br/>
/// Note that ${#...} is expanded at compile time, thus can be nested inside ${} and #{} expressions.
/// Additionally, ${} expressions are expanded before #{} ones, so they can be nested.  For example:
/// <pre>#{$ZCVT("${NAMESPACE}","L")}</pre>
Method Evaluate(pExpr As %String) As %String [ Internal ]
{
	#dim tSC As %Status
	#dim tSC2 As %Status
	#dim tResult As %String
	#dim tLogLevel As %Integer
	Set tSC=$$$OK,$ZT="Trap",tResult=pExpr,tLogLevel=..LogLevel,..LogLevel=-1
	Do {
		// First, let's evaluate ${} variables
		Set tSC = ..evalVars(pExpr,.tResult)

		// Next, let's evaluate @{} variables
		Set tSC2 = ..evalSpecial(tResult,.tResult)
		Set:$$$ISERR(tSC2) tSC=$$$ADDSC(tSC,tSC2)

		// Finally, let's evaluate #{} expressions
		Set tSC2 = ..evalExpr(tResult,.tResult)
		Set:$$$ISERR(tSC2) tSC=$$$ADDSC(tSC,tSC2)
		
	} While(0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Set ..LogLevel=tLogLevel
	Do ..Log(3,"Evaluate",pExpr_" -> "_tResult)
	
	Quit tResult
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Evaluate X{} variables
Method evalToken(pExpr As %String, pType As %String, pFunction As %String, Output pResult As %String) As %Status [ Internal, Private ]
{
	#dim p,q,tVariable,tValue,tToken,tSC
	Set tSC=$$$OK,pResult=pExpr
	While(1) {
		Set p=$FIND(pResult,pType_"{")
		Quit:'p
		
		Set q=$FIND(pResult,"}",p)
		Quit:'q
		
		// Grab the token
		Set tToken = $EXTRACT(pResult,p,q-($L(pType)+1))
		Set %objlasterror = $$$OK
		Set tValue = $method($this,pFunction,tToken)
		Set:$$$ISERR(%objlasterror) tSC=$$$ADDSC(tSC,%objlasterror)
	
		// Insert the new value
		Set pResult = $EXTRACT(pResult,1,p-3)_$GET(tValue)_$EXTRACT(pResult,q,$LENGTH(pResult))
	}
	Quit tSC
}

/// Evaluate ${} variables
Method evalVars(pExpr As %String, Output pResult As %String) As %Status [ Internal, Private ]
{
	Quit ..evalToken(pExpr, "$", "GetVariable", .pResult)
}

/// Evaluate #{} variables
Method evalExpr(pExpr As %String, Output pResult As %String) As %Status [ Internal, Private ]
{
	Quit ..evalToken(pExpr, "#", "eval", .pResult)
}

/// Evaluate a CoS expression
Method eval(pExpr As %String) As %String [ Internal ]
{
	Set $ZT="evalTrap",%objlasterror=$$$OK
	Quit @pExpr
evalTrap
	Set %objlasterror = $$$ERROR($$$InstallerInvalidExpression,$GET(pExpr),$ZE)
	Quit "?"
}

/// Evaluate @{} variables
Method evalSpecial(pExpr As %String, Output pResult As %String) As %Status [ Internal, Private ]
{
	Quit ..evalToken(pExpr, "@", "special", .pResult)
}

/// Evaluate special variables
Method special(pVar As %String) As %String [ Internal ]
{
	Quit:$ZCVT(pVar,"U")="INSTALLER" "%this"
	Set %objlasterror = $$$ERROR($$$InstallerInvalidSpecialVariable,$GET(pVar))
	Quit "$$$NULLOREF"
}

/// Create a database
Method CreateDatabase(pName As %String, pDir As %String, pCreate As %String, pResource As %String = "", pPublicPermissions As %String = "RW", pEncrypted As %Boolean = 0, pEncryptionKeyID As %String = "", pBlockSize As %Integer = "", pInitialSize As %Integer = "", pMaximumSize As %Integer = "", pExpansionSize As %Integer = "", pCollation As %String = "", pStreamLocation As %String = "", pClusterMountMode As %Boolean = "", pMountAtStartup As %Boolean = "", pMountRequired As %Boolean = "") [ Internal ]
{
	#define KILLIFEMPTY(%v) Kill:$G(%v)="" %v
	#define SETIF(%v,%a,%p) Set:$G(%v)'="" %a(%p)=%v
	#dim tSC As %Status
	#dim tExists As %Boolean
	
	// First, normalize the directory name
	Set pDir = ##class(%File).NormalizeDirectory(pDir)
	Set tExists = ##class(%File).Exists(pDir_$$$UCFILENAME_".DAT")
	
	Do ..Log(1,"CreateDatabase","Creating database "_pName_" in "_pDir_" with resource "_pResource)
	
	// Are we trying to create the database?
	If pCreate'="no" {
		If 'tExists || (pCreate="overwrite") {
			// If the CACHE.DAT doesn't exist, or we want to overwrite it, let's create it
			If '##class(%File).DirectoryExists(pDir) {
				// Make sure the directory exists first
				If '##class(%File).CreateDirectoryChain(pDir) {
					Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR($$$DirectoryCannotCreate,pDir))
				}
			}
				
			Do ..Log(2,"CreateDatabase",$S(tExists:"Creating",1:"Overwriting")_" "_pDir_$$$UCFILENAME_".DAT")
		
			$$$KILLIFEMPTY(pBlockSize)
			$$$KILLIFEMPTY(pInitialSize)
			$$$KILLIFEMPTY(pExpansionSize)
			$$$KILLIFEMPTY(pMaximumSize)
			$$$KILLIFEMPTY(pCollation)
			$$$KILLIFEMPTY(pClusterMountMode)		
			Kill:'$G(pEncrypted) pEncryptionKeyID
			
			// We always pass reinit=1, so the system will either create a new DB, or reinitialize an existing one (as if it was new)
			#dim tReInit As %Boolean = 1
			
			// Physically create the database
			Set tSC = $$CreateDatabase^%SYS.DATABASE(pDir,.pBlockSize,.pInitialSize,,.pExpansionSize,.pMaximumSize,,,,,.pCollation,,.tReInit,.pClusterMountMode,.pEncryptionKeyID)
			If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
			
			If pResource="" {
				// Must have a resource when creating a new database
				Set pResource=..#DEFAULTDBRESOURCE
				
				Do ..Log(2,"CreateDatabase","No resource specified for new database "_pName_", using: '"_pResource_"'")
			}
		} Else {
			// Create new, but file already exists
			Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR($$$FileExists))
		}
	}
	
	// Check that the database actually exists now ...
	If '##class(%File).Exists(pDir_$$$UCFILENAME_".DAT") {
		Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR($$$DatabaseNotThere))
	}

	// Add the database to to the configuration, if necessary
	If '##Class(Config.Databases).Exists(pName) {
		Do ..Log(2,"CreateDatabase","Adding database "_pName)
		
		#dim p
		k p
		s p("Directory")=pDir
		$$$SETIF(pClusterMountMode,p,"ClusterMountMode")
		$$$SETIF(pMountAtStartup,p,"MountAtStartup")
		$$$SETIF(pMountRequired,p,"MountRequired")
		$$$SETIF(pStreamLocation,p,"StreamLocation")
		Set tSC  = ##Class(Config.Databases).Create(pName,.p)
		If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	}
	
	If pResource'="" {
		// Finally, assign a resource
		Do ..Log(2,"CreateDatabase","Creating and assigning resource '"_pResource_"' to "_pName)
		Set tSC = ##class(%EnsembleMgr).assignResourceToDB(pResource,pDir,pPublicPermissions)
		If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	}
}

/// Create a namespace
Method CreateNamespace(pNamespace As %String, pCodeDB As %String, pDataDB As %String, pFlags As %String) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	s pNamespace=$zcvt(pNamespace,"U")
	Do {
		Do ..Log(1,"CreateNamespace","Creating namespace "_pNamespace_" using "_pCodeDB_"/"_pDataDB)

		#dim p
		
		// Now, create the namespace
		If '##Class(Config.Namespaces).Exists(pNamespace) {
			Do ..Log(2,"CreateNamespace","Adding namespace "_pNamespace)
			
			k p
			s p("Globals")=pDataDB
			s p("Routines")=pCodeDB
			Set tSC = ##Class(Config.Namespaces).Create(pNamespace,.p)
			Quit:$$$ISERR(tSC)
		} Else {
			Do ..Log(2,"CreateNamespace","Modifying namespace "_pNamespace)
			
			k p
			s p("Globals")=pDataDB
			s p("Routines")=pCodeDB
			Set tSC = ##Class(Config.Namespaces).Modify(pNamespace,.p)
			Quit:$$$ISERR(tSC)			
		}
		
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Enable a namespace for Interoperability productions
Method EnableEnsemble(pNamespace As %String, pEnsPortalSuffix As %String = "", pEnsPortalPrefix As %String = "", pGrant As %String, pCookiePath As %String, pAuthMethods As %Integer) [ Internal ]
{
	Set tSC = ##class(%Library.EnsembleMgr).EnableNamespace(pNamespace,..LogLevel>1,.tIsPrimary,0,0,.pEnsPortalSuffix,.pEnsPortalPrefix,pGrant,pCookiePath,pAuthMethods)
	$$$ThrowOnError(tSC)
}

/// Create a class mapping into 'pNamespace', of 'pSpec' from the 'pFrom' namespace
Method ClassMapping(pNamespace As %String, pSpec As %String, pFrom As %String)
{
	#dim tSC As %Status
	Set tSC = $$$OK
	s pNamespace=$zcvt(pNamespace,"U")
	Do ..Log(1,"ClassMapping","Adding classmapping "_pSpec_" to "_pNamespace_" from "_pFrom)
	If '##Class(Config.MapPackages).Exists(pNamespace,pSpec) {		
		#dim p
		
		k p
		s p("Database")=pFrom
		Set tSC = ##Class(Config.MapPackages).Create(pNamespace,pSpec,.p,,$$$CPFSave)
	}
	If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
}

/// Create a global mapping into 'pNamespace', of 'pSpec' from the 'pFrom' namespace
Method GlobalMapping(pNamespace As %String, pSpec As %String, pFrom As %String, pCollation As %Integer = "") [ Internal ]
{
	#dim tSC As %Status
	Set tSC = $$$OK
	s pNamespace=$zcvt(pNamespace,"U")
	
	Do ..Log(1,"GlobalMapping","Adding globalmapping "_pSpec_" to "_pNamespace_" from "_pFrom)
	
	If '##Class(Config.MapGlobals).Exists(pNamespace,pSpec) {
		#dim p
		
		k p
		s p("Database")=pFrom
		s:pCollation'="" p("Collation")=pCollation
		Set tSC = ##Class(Config.MapGlobals).Create(pNamespace,pSpec,.p,,$$$CPFSave)
	}
	If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
}

/// Create a routine mapping into 'pNamespace', of 'pSpec' from the 'pFrom' namespace
Method RoutineMapping(pNamespace As %String, pSpec As %String, pType As %String, pFrom As %String) [ Internal ]
{
	#dim tSC As %Status
	#dim tExt As %String
	#dim tSpec As %String
	Set tSC = $$$OK
	s pNamespace=$zcvt(pNamespace,"U")
	
	Do ..Log(1,"RoutineMapping","Adding routinemapping "_pSpec_"."_pType_" to "_pNamespace_" from "_pFrom)
	
	If '##Class(Config.MapRoutines).Exists(pNamespace,pSpec_"_"_pType) {
		#dim p
		
		k p
		s p("Database")=pFrom
		Set tSC = ##Class(Config.MapRoutines).Create(pNamespace,pSpec_"_"_pType,.p,,$$$CPFSave)
	}
	If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
}

/// Copy a file
Method CopyFile(pSrc As %String, pTarget As %String, pIgnoreErrors As %Boolean = 0) [ Internal ]
{
	Do ..Log(1,"CopyFile","Copying file "_pSrc_" to "_pTarget)
	If '##class(%File).CopyFile(pSrc, pTarget),'pIgnoreErrors {
		Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR($$$FileCanNotCopy,pSrc,pTarget))
	}
}

/// Copy a directory
Method CopyDir(pSrc As %String, pTarget As %String, pIgnoreErrors As %Boolean = 0) [ Internal ]
{
	#dim tSC As %Status
	Do ..Log(1,"CopyDir","Copying directory "_pSrc_" to "_pTarget)
	Set %objlasterror = $$$OK
	If '##class(%File).CopyDir(pSrc, pTarget,1),'pIgnoreErrors {
		Set tSC=$SELECT($$$ISERR(%objlasterror):%objlasterror,1:$$$ERROR($$$FileCanNotCopy,pSrc,pTarget))
		Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	}
}

/// Copy a class
Method CopyClass(pSrc As %String, pTarget As %String, pReplace As %Boolean = 0) [ Internal ]
{
	#dim tSrcDef,tTargetDef As %Dictionary.ClassDefinition
	#dim tSC As %Status
	
	If '##class(%Dictionary.ClassDefinition).%ExistsId(pSrc) {
		Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR($$$ClassDoesNotExist,pSrc))
	}
	
	If ##class(%Dictionary.ClassDefinition).%ExistsId(pTarget) {
		If pReplace {
			Do ##class(%Dictionary.ClassDefinition).%DeleteId(pTarget)
		} Else {
			Quit
		}
	}
	
	Set tSrcDef = ##class(%Dictionary.ClassDefinition).%OpenId(pSrc)
	Set tTargetDef = tSrcDef.%ConstructClone(1)
	Set tTargetDef.Name = pTarget
	
	Set tSC = tTargetDef.%Save()
	
	If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
}

/// Check to see if a class exists
Method ClassExists(pTarget As %String, pNamespace As %String = {$NAMESPACE}) As %Boolean [ Internal ]
{
	#dim tExists As %Boolean
	Do ..PushNS(pNamespace)
	Set tExists = ##class(%Dictionary.ClassDefinition).%ExistsId(pTarget)
	Do ..PopNS()
	Quit tExists
}

/// Production settings
Method Production(pNamespace As %String, pProduction As %String, pAutoStart As %Boolean, ByRef pSettings, ByRef pCredentials) [ Internal ]
{
	Set tSC = $$$OK
	Set pNamespace=$zcvt(pNamespace,"U")
	Do ..Log(1,"Production","Production "_pProduction_" in "_pNamespace_": AutoStart="_pAutoStart)

	If ('pAutoStart) && ($GET(^|pNamespace|Ens.AutoStart)=pProduction) {
		Set tSC = ##class(%EnsembleMgr).SetAutoStart(pNamespace,"")
	}
	If pAutoStart {
		Set tSC = ##class(%EnsembleMgr).SetAutoStart(pNamespace,pProduction)
	}
	If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)

	If $DATA(pSettings) {
		
		If ..IsLoggable(2) {
			#dim tItem,tTarget,tSetting
			Set tItem = ""
			For {
				Set tItem = $O(pSettings(tItem)) Quit:tItem=""
				Set tTarget = ""
				For {
					Set tTarget = $O(pSettings(tItem,tTarget)) Quit:tTarget=""
					Set tSetting = ""
					For {
						Set tSetting = $O(pSettings(tItem,tTarget,tSetting)) Quit:tSetting=""
						
						// Log this ...
						Do ..Log(2,"Production",tItem_"("_tTarget_")."_tSetting_" = "_pSettings(tItem,tTarget,tSetting))
					}
				}
			}
		}
		
		Set tSC = ##class(%EnsembleMgr).ApplySettings(pNamespace,pProduction,.pSettings)
		If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)		
	}
	If $DATA(pCredentials) {
		If ..IsLoggable(2) {
			#dim tName,tUsername,tPassword,tOverwrite
			Set tName=""
			For {
				Set tName = $O(pCredentials(tName)) Quit:tName=""
				Set tUsername  = $LG(pCredentials(tName),1)
				Set tPassword  = $LG(pCredentials(tName),2)
				Set tOverwrite = +$LG(pCredentials(tName),3)
				
				Do ..Log(2,"Production",tName_" -> "_tUsername_"/"_$TR($J("",$L(tPassword))_" ("_tOverwrite_")"," ","*"))
				
				// Store this credential
				Set tSC = ##class(%EnsembleMgr).SetCredential(pNamespace,tName,tUsername,tPassword,tOverwrite)
				If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
			}
		}
	}
}

/// Check to see if a production exists
Method ProductionExists(pTarget As %String, pNamespace As %String = {$NAMESPACE}) As %Boolean [ Internal ]
{
	#dim tExists As %Boolean
	s pNamespace=$zcvt(pNamespace,"U")
	Do ..PushNS(pNamespace)
	Set tExists = ##class(Ens.Config.Production).%ExistsId(pTarget)
	Do ..PopNS()
	Quit tExists
}

/// Create/modify a CSP application
Method CSPApplication(pUrl As %String, pNamespace As %String, pDescription As %String, pDirectory As %String, pResource As %String, pRecurse As %String, pLoginClass As %String, pCookiePath As %String, pAuthMethods As %Integer, pLockCSPName As %Boolean, pEventClass As %String, pDefaultTimeout As %Integer, pDefaultSuperclass As %String, pUseSessionCookie As %Integer, pServeFiles As %Boolean, pServeFilesTimeout As %Integer, pCustomErrorPage As %String, pPackageName As %String, pChangePasswordPage As %String, pGroupById As %String = "", pCspZenEnabled As %Boolean = 1, pInboundWebServicesEnabled As %Boolean = 1, pTwoFactorEnabled As %Boolean = 0, pIsNameSpaceDefault As %Boolean = 0, pPermittedClasses As %String = "", pAutoCompile As %Boolean = 1, pDispatchClass As %String = "", pMatchRoles As %String = "", pGrant As %String = "", pSessionScope As %Integer, pUserCookieScope As %Integer, pCSRFToken As %Boolean, pDeepSeeEnabled As %Boolean, piKnowEnabled As %Boolean, pJWTAuthEnabled As %Boolean, pJWTAccessTokenTimeout As %Integer, pJWTRefreshTokenTimeout As %Integer, pRedirectEmptyPath As %Boolean, pWSGIAppLocation As %String, pWSGIAppName As %String, pWSGICallable As %String, pWSGIDebug As %Boolean, pWSGIType As %Integer) [ Internal ]
{
	#define SETIF(%v,%a,%p) Set:$G(%v)'="" %a(%p)=%v

	#dim tSC As %Status
	s pNamespace=$zcvt(pNamespace,"U")

	
	If $GET(pUrl)="" {
		Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR($$$ApplicationInvalidName,pUrl))
	}
	If $GET(pNamespace)="" {
		Throw ##class(%Installer.Exception).CreateFromStatus($$$ERROR($$$CSPAppNamespaceRequired,pUrl))
	}

	#dim Properties
	Set Exists = ##class(Security.Applications).Exists(pUrl, .tApp, .tSC)

	If 'Exists {
		If ('$DATA(pAuthMethods)) || (pAuthMethods=0) {
			Set pAuthMethods = ##class(%EnsembleMgr).DetermineCSPAppSec()
		}
		Set:$G(pCookiePath)="" pCookiePath = pUrl
		Do ..Log(1,"CSPApplication","Creating "_pUrl_" in "_pNamespace)
	} Else {
		If ($GET(pMatchRoles)'="") || ($GET(pGrant)'="") {
			Set tSC = ##class(Security.Applications).Get(pUrl,.Properties)
			If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
		}
		Do ..Log(1,"CSPApplication","Updating "_pUrl_" in "_pNamespace)
	}
	
	$$$SETIF(pNamespace,Properties,"NameSpace")
	$$$SETIF(pDescription,Properties,"Description")
	$$$SETIF(pDirectory,Properties,"Path")
	$$$SETIF(pResource,Properties,"Resource")
	$$$SETIF(pRecurse,Properties,"Recurse")
	$$$SETIF(pLoginClass,Properties,"LoginPage")
	$$$SETIF(pCookiePath,Properties,"CookiePath")
	$$$SETIF(pAuthMethods,Properties,"AutheEnabled")
	$$$SETIF(pLockCSPName,Properties,"LockCSPName")
	$$$SETIF(pEventClass,Properties,"EventClass")
	$$$SETIF(pDefaultTimeout,Properties,"Timeout")
	$$$SETIF(pDefaultSuperclass,Properties,"SuperClass")
	$$$SETIF(pUseSessionCookie,Properties,"UseCookies")
	$$$SETIF(pServeFiles,Properties,"ServeFiles")
	$$$SETIF(pServeFilesTimeout,Properties,"ServeFilesTimeout")
	$$$SETIF(pCustomErrorPage,Properties,"ErrorPage")
	$$$SETIF(pPackageName,Properties,"Package")
	$$$SETIF(pChangePasswordPage,Properties,"ChangePasswordPage")
	$$$SETIF(pGroupById,Properties,"GroupById")
	$$$SETIF(pCspZenEnabled,Properties,"CSPZENEnabled")
	$$$SETIF(pInboundWebServicesEnabled,Properties,"InbndWebServicesEnabled")
	$$$SETIF(pTwoFactorEnabled,Properties,"TwoFactorEnabled")
	$$$SETIF(pIsNameSpaceDefault,Properties,"IsNameSpaceDefault")
	$$$SETIF(pPermittedClasses,Properties,"PermittedClasses")
	$$$SETIF(pAutoCompile,Properties,"AutoCompile")
	$$$SETIF(pDispatchClass,Properties,"DispatchClass")
	$$$SETIF(pSessionScope,Properties,"SessionScope")
	$$$SETIF(pUserCookieScope,Properties,"UserCookieScope")
	$$$SETIF(pCSRFToken,Properties,"CSRFToken")
	$$$SETIF(pDeepSeeEnabled,Properties,"DeepSeeEnabled")
	$$$SETIF(piKnowEnabled,Properties,"iKnowEnabled")
	$$$SETIF(pJWTAuthEnabled,Properties,"JWTAuthEnabled")
	$$$SETIF(pJWTAccessTokenTimeout,Properties,"JWTAccessTokenTimeout")
	$$$SETIF(pJWTRefreshTokenTimeout,Properties,"JWTRefreshTokenTimeout")
	$$$SETIF(pRedirectEmptyPath,Properties,"RedirectEmptyPath")
	$$$SETIF(pWSGIAppLocation,Properties,"WSGIAppLocation")
	$$$SETIF(pWSGIAppName,Properties,"WSGIAppName")
	$$$SETIF(pWSGICallable,Properties,"WSGICallable")
	$$$SETIF(pWSGIDebug,Properties,"WSGIDebug")
	$$$SETIF(pWSGIType,Properties,"WSGIType")

	If ($GET(pMatchRoles)'="") || ($GET(pGrant)'="") {
		// Extract existing MatchRoles and ApplicationRoles from Properties("MatchRoles") if we don't change both
		Set tMatchRoles = ""
		Set tApplicationRoles = ""
		If Exists && (($GET(pMatchRoles)="") || ($GET(pGrant)="")) {
			For i=1:1:$LENGTH(Properties("MatchRoles"),",") {
			Set matchElement = $PIECE(Properties("MatchRoles"),",",i)
			// ApplicationRoles has empty MatchRole (MatchRole:TargetRole1:TargetRole2)
			If ($PIECE(matchElement,":")="") {
				Set tApplicationRoles = matchElement
			} Else {
				Set tMatchRoles = tMatchRoles_matchElement_","
			}
		}
			Set tMatchRoles = $ZSTRIP(tMatchRoles,">",",")
		}

		// Update MatchRoles and ApplicationRoles if pMatchRoles and pGrant are set
		Set:$GET(pMatchRoles)'="" tMatchRoles = pMatchRoles
		// Convert tGrant to format :grant1:grant2 etc
		Set:$GET(pGrant)'="" tApplicationRoles = ":"_$LISTTOSTRING($LISTFROMSTRING($ZSTRIP(pGrant,"<=>",",")), ":")
		Set Properties("MatchRoles") = $LISTTOSTRING($LISTBUILD(tMatchRoles, tApplicationRoles), ",")
	}

	Set Properties("Type") = $$$AppTypeCSP
	Set Properties("Enabled") = 1

	If 'Exists {
		Set tSC = ##class(Security.Applications).Create(pUrl,.Properties)
		If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	} Else {
		Set tSC = ##class(Security.Applications).Modify(pUrl,.Properties)
		If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	}
}

/// Import a file (or directory)
Method Import(pNamespace As %String, pTarget As %String, pFlags As %String, pIgnoreErrors As %String = "", pRecurse As %Boolean = 0) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	New $NAMESPACE
	s pNamespace=$zcvt(pNamespace,"U")
	Do {
		Do ..Log(1,"Import","Loading "_pTarget_" (isdir="_##class(%File).DirectoryExists(pTarget)_") into "_pNamespace_", recurse="_pRecurse)

		Set:pNamespace'=$NAMESPACE $NAMESPACE=pNamespace
		If ##class(%File).DirectoryExists(pTarget) {
			// We use ImportDir() as it compiles things in the right order (i.e. MAC vs CLS)
			Set tSC = $system.OBJ.ImportDir(pTarget,,pFlags,,pRecurse)
		} Else {
			Set tSC = $system.OBJ.Load(pTarget,pFlags)
		}

		// If there are errors, we can either ignore them all, or specific error(s)
		If $$$ISERR(tSC),(pIgnoreErrors=1)||((","_pIgnoreErrors_",")[(","_$P($system.Status.GetErrorCodes(tSC),",")_",")) {
			Do ..Log(2,"Import","Ignoring Errors: ("_$P($system.Status.GetErrorCodes(tSC),",")_") "_$system.Status.GetErrorText(tSC))
			Set tSC = $$$OK
		}
		
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Load CSP pages
Method LoadPage(pNamespace As %String, pName As %String, pDir As %String, pFlags As %String, pIgnoreErrors As %Boolean = 0) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	New $NAMESPACE
	s pNamespace=$zcvt(pNamespace,"U")
	Do {
		Set:pNamespace'=$NAMESPACE $NAMESPACE=pNamespace
		
		If pName'="" {
			Do ..Log(1,"LoadPage","Loading "_pName_" into "_pNamespace)
			Set tSC = $$$ADDSC(tSC,$system.CSP.LoadPage(pName,pFlags))
		}
		
		If pDir'="" {
			Do ..Log(1,"LoadPage","Loading directory "_pDir_" into "_pNamespace)
			Set tSC = $$$ADDSC(tSC,$system.CSP.LoadPageDir(pDir,pFlags))
		}

		If $$$ISERR(tSC),pIgnoreErrors {
			Do ..Log(2,"LoadPage","Ignoring Errors: "_$system.Status.GetErrorText(tSC))
			Set tSC = $$$OK
		}
		
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Compile
Method Compile(pNamespace As %String, pClass As %String, pFlags As %String, pIgnoreErrors As %Boolean = 0) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	New $NAMESPACE
	s pNamespace=$zcvt(pNamespace,"U")
	Do {
		Do ..Log(1,"Compile","Compiling "_pClass_" in "_pNamespace_" (flags="_pFlags_")")

		Set:pNamespace'=$NAMESPACE $NAMESPACE=pNamespace
		Set tSC = $system.OBJ.Compile(pClass,pFlags)
		
		If $$$ISERR(tSC),pIgnoreErrors {
			Do ..Log(2,"Compile","Ignoring Errors: "_$system.Status.GetErrorText(tSC))
			Set tSC = $$$OK
		}
		
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Set a system setting
Method SystemSetting(pItem As %String, pValue As %String) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tClass As %String
		#dim tProperty As %String
		
		Do ..Log(1,"SystemSetting","Setting "_pItem_" to "_pValue)
		s tClass=$p(pItem,".",1,$l(pItem,".")-1)
		s tProperty=$p(pItem,".",$l(pItem,"."))
		
		#dim p
		k p
		s p(tProperty)=pValue
		s tSC=$classmethod(tClass,"Modify",.p)
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	// Most likely a <PROPERTY DOES NOT EXIST> error
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Create a security resource
Method CreateResource(pName As %String, pDescription As %String, pPermission As %String, pType As %Integer = 0) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tExists As %Boolean
		Set tExists = ##class(Security.Resources).Exists(pName)
		
		Do ..Log(1,"CreateResource",$S(tExists:"Modifying",1:"Creating")_" Resource '"_pName_"' with public permission(s) '"_pPermission_"', type="_pType)
		If 'tExists {
			// Create a new resource
			Set tSC = ##class(Security.Resources).Create(pName,pDescription,pPermission,pType)
		} Else {
			// Role already exists, let's modify
			#dim tProperties
			Set tProperties("Description")=pDescription
			Set tProperties("Type")=pType
			Set tProperties("PublicPermission")=pPermission

			// Now, modify this resource
			Set tSC = ##class(Security.Resources).Modify(pName, .tProperties)
		}
		
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Create a security role
Method CreateRole(pName As %String, pDescription As %String, pResources As %String, pRolesGranted As %String) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tExists As %Boolean
		Set tExists = ##class(Security.Roles).Exists(pName)
		
		Do ..Log(1,"CreateRole",$S(tExists:"Modifying",1:"Creating")_" Role '"_pName_"' with resources '"_pResources_"', granting '"_pRolesGranted_"'")
		If 'tExists {
			// Create a new role
			Set tSC = ##class(Security.Roles).Create(pName,pDescription,pResources,pRolesGranted)
		} Else {
			// Role already exists, let's modify
			#dim tProperties
			// NOTE: Description cannot be currently modified
			//Set tProperties("Description")=pDescription
			Set tProperties("Resources")=pResources
			Set tProperties("GrantedRoles")=pRolesGranted

			// Now, modify this role
			Set tSC = ##class(Security.Roles).Modify(pName, .tProperties)
		}
		
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Create a security user
Method CreateUser(pUsername As %String, pRoles As %String, pPassword As %String, pFullName As %String, pNamespace As %String, pRoutine As %String, pExpirationDate As %String, pChangePassword As %Boolean, pEnabled As %Boolean, pComment As %String, pFlags As %String = 1) [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	s pNamespace=$zcvt(pNamespace,"U")
	Do {
		#dim tExists As %Boolean
		Set tExists = ##class(Security.Users).Exists(pUsername)
		
		Do ..Log(1,"CreateUser",$S(tExists:"Modifying",1:"Creating")_" user '"_pUsername_"' with roles '"_pRoles_"' for: "_pFullName)

		If 'tExists {
			// Create a new user
			Set tSC = ##class(Security.Users).Create(pUsername,
													 pRoles,
													 pPassword,
													 pFullName,
													 pNamespace,
													 pRoutine,
													 pExpirationDate,
													 pChangePassword,
													 pEnabled,
													 pComment,
													 pFlags)
		} Else {
			// User already exists, let's modify
			#dim tProperties
			Set tProperties("Roles")=pRoles
			Set tProperties("Password")=pPassword
			Set tProperties("FullName")=pFullName
			Set tProperties("NameSpace")=pNamespace
			Set tProperties("Routine")=pRoutine
			Set tProperties("ExpirationDate")=pExpirationDate
			Set tProperties("ChangePassword")=pChangePassword
			Set tProperties("Enabled")=pEnabled
			Set tProperties("Comment")=pComment

			// Now, modify this user
			Set tSC = ##class(Security.Users).Modify(pUsername, .tProperties)
		}

	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
	Quit
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Activate a configuration
Method ActivateConfiguration(pTargetNS As %String) [ Internal ]
{
	#dim Status As %Status
	s pTargetNS=$zcvt(pTargetNS,"U")
	
	Do ..Log(1,"ActivateConfiguration","Activating Configuration")
	
	s Status=##Class(Config.CPF).Write()
	If $$$ISERR(Status) Throw ##class(%Installer.Exception).CreateFromStatus(Status)
	s Status=##Class(Config.Map).MoveToActive(pTargetNS)
	If $$$ISERR(Status) Throw ##class(%Installer.Exception).CreateFromStatus(Status)
 	s Status=##Class(Config.Namespaces).Load(pTargetNS)
	If $$$ISERR(Status) Throw ##class(%Installer.Exception).CreateFromStatus(Status)
}

/// Construct a new instance of a %Installer.Installer object
Method %OnNew(ByRef pConfigFile As %RawString, ByRef pVars, pLogLevel As %Integer = 0, pLogger = {$$$NULLOREF}) As %Status [ Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..Logger = $SELECT($IsObject(pLogger):pLogger,1:##class(AbstractLogger).%New())
	Set ..LogLevel = pLogLevel
	Do ..setupVars(.pVars)
	
	Quit $$$OK
}

/// Log to the installer log
Method Log(pLevel As %Integer, pTopic As %String, Args...) [ Internal ]
{
	If ..IsLoggable(pLevel) {
		Do ..Logger.LogEntry(pLevel, pTopic, .Args)
	}
}

/// Check to see if a particular log level will cause logging
Method IsLoggable(pLevel As %Integer) As %Boolean [ CodeMode = expression, Internal ]
{
(pLevel'>..LogLevel)&&$IsObject(..Logger)
}

/// Setup initial variables
Method setupVars(ByRef pVars) [ Internal, Private ]
{
	// Set up some basic variables
	Set ..Variables("VERSION")    = $System.Version.GetNumber()
	Set ..Variables("PLATFORM")   = $System.Version.GetOS()
	Set ..Variables("PROCESSOR")  = $System.Version.GetPlatform()
	Set ..Variables("CPUCOUNT")   = $System.Util.NumberOfCPUs()
	Set ..Variables("BINDIR")     = $System.Util.BinaryDirectory()
	Set ..Variables("ROOTBINDIR") = $System.Util.InstallDirectory()
	Set ..Variables("INSTALLDIR") = $System.Util.DataDirectory()
	Set ..Variables("DATADIR")    = $System.Util.DataDirectory()	
	Set ..Variables("MGRDIR")     = $system.Util.ManagerDirectory()
	Set ..Variables("CFGNAME")    = $PIECE($ZUTIL(86),"*",2)
	Set ..Variables("CFGFILE")    = $PIECE($ZUTIL(86),"*")
	Set ..Variables("CFGDIR")     = $System.Util.DataDirectory()
	Set ..Variables("CSPDIR")     = ##class(%File).NormalizeDirectory(##class(%File).SubDirectoryName($System.Util.DataDirectory(),"csp"))
	Set ..Variables("PORT")		  = $GET(^%SYS("SSPort"),1972)
	s Status=##Class(%Library.RoutineMgr).GetWebServerPort(.Port,.Server,.URLPrefix,.URL)
	Set ..Variables("HTTPPORT")	  = Port
	Set ..Variables("HOSTNAME")	  = Server
	
	// Now, overlay any user settings
	Merge ..Variables = pVars
}

/// Process macro arguments for $$$EVAL
ClassMethod macroArgs(pArgs As %List) As %String [ Internal ]
{
	#dim tResult,tArg As %String
	#dim i

	Set tResult = ""
	For i=1:1:$LL(pArgs) {
		Set tArg = $LG(pArgs,i)
		Set:i>1 tResult = tResult_","

		Set tResult = tResult _ ..macroArg(tArg)
	}
	
	Quit tResult
}

/// Process a single macro argument for $$$EVAL
ClassMethod macroArg(pArg As %String) As %String [ Internal ]
{
	#dim tResult,tArg As %String

	Set tArg = ..quote(..preEval(pArg))
	Set tResult = $SELECT((tArg["${")||(tArg["#{"):"tInstaller.Evaluate("_tArg_")",1:tArg)

	Quit tResult
}

/// Pre-evaluate a $$$EVAL argument to expand references to class parameters
ClassMethod preEval(pExpr As %String) As %String [ Internal, Private ]
{
	#dim p,q,tParameter,tValue,tResult
	Set tResult=pExpr
	While(1) {
		Set p=$FIND(tResult,"${#")
		Quit:'p
		
		Set q=$FIND(tResult,"}",p)
		Quit:'q
		
		// Grab the variable name
		Set tParameter = $EXTRACT(tResult,p,q-2)		
		$$$comMemberKeyGetLvar(tValue,%classname,$$$cCLASSparameter,tParameter,$$$cPARAMdefault)
	
		// Insert the new value
		Set tResult = $EXTRACT(tResult,1,p-4)_$GET(tValue)_$EXTRACT(tResult,q,$LENGTH(tResult))
	}
	Quit tResult
}

/// Quote a string
ClassMethod quote(pValue As %String) As %String [ Internal ]
{
	#dim tResult,tCh As %String
	#dim i

	Set tResult = ""
	For i=1:1:$LENGTH(pValue) {
		Set tCh = $EXTRACT(pValue,i)
		Set tResult = tResult _ tCh
		Set:tCh="""" tResult = tResult _ tCh
	}
	
	Quit """"_tResult_""""
}

/// Convert a parameter list of the form:
///     A=1,B=2,C="3,4,5",D=6,E="7,""Q"",8",F=9
/// Into an array of named/values:
///     a("A")=1
///     a("B")=2
///     a("C")="3,4,5"
///     a("D")=6
///     a("E")="7,""Q"",8"
///     a("F")=9
/// If <var>pNamed</var> is false, then the position is used as a name:
///     1,2,"3,4,5",6,"7,""Q"",8",9
/// Becomes:
///     a(1)=1
///     a(2)=2
///     a(3)="3,4,5"
///     a(4)=6
///     a(5)="7,""Q"",8"
///     a(6)=9
ClassMethod processParamsIntoArray(pParams As %String, pNamed As %Boolean, ByRef pArray) As %Status [ Internal ]
{
	/*
		The parameter list should conform to the following BNF grammar:
		
			paramlist = (paramitem (',' paramitem)*)? (',')?
		#if pNamed
			paramitem = name '=' value
		#else
			paramitem = value
		#endif
			name	  = [A-Za-z0-9][A-Za-z0-9_]*
			value     = strlit | notcomma+
			strlit	  = '"' (notquote | '""')* '"'
			notcomma  = [^\,]
			notquote  = [^\"]
	*/
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tPtr As %Integer = 1
		#dim tFlags
		
		If '$G(pNamed) {
			Set tFlags("autoname")=0
		}
		
		Kill pArray
	
		Set tSC = $$paramlist(pParams,.tPtr,.tFlags,.pArray)
		Quit:$$$ISERR(tSC)
	
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
	
#define ISTOK(%token) $S(ptr+($L(%token)-1)>$L(str):"",1:$E(str,ptr,ptr+($L(%token)-1))=%token)
#define NEXT Set ptr=ptr+1

#dim sc As %Status
#dim str As %String
#dim ptr As %Integer
#dim flags
#dim out
	
paramlist(str,ptr,flags,out)
	Set sc=$$$OK
	If ptr'>$L(str) {
		Set sc = $$paramitem(str,.ptr,.flags,.out)
		Quit:$$$ISERR(sc) sc
		
		While ($$$ISTOK(",")) {
			$$$NEXT
			
			If ptr>$L(str) Quit  // Allow for a trailing comma at the end of the line
			
			Set sc = $$paramitem(str,.ptr,.flags,.out)
			Quit:$$$ISERR(sc)
		}
	}
	
	Quit sc
	
paramitem(str,ptr,flags,out)
#dim name As %String
#dim value As %String
	If '$DATA(flags("autoname")) {
		Set sc = $$name(str,.ptr,.name)
		Quit:$$$ISERR(sc) sc
		
		If '$$$ISTOK("=") {
			Quit $$$ERROR($$$InstallerParserError,"=",ptr,$E(str,ptr,*))
		}
		$$$NEXT
	} Else {
		Set name = $INCREMENT(flags("autoname"))
	}
	
	Set sc = $$value(str,.ptr,.value)
	Quit:$$$ISERR(sc) sc
	
	Set out(name)=value
	Quit $$$OK
	
name(str,ptr,name)
	Set name="",count=0
	While (ptr'>$L(str) && $S(count>0:$E(str,ptr)?1(1AN,1"_"),1:$E(str,ptr)?1AN)) {
		Set name=name_$E(str,ptr),count=count+1
		$$$NEXT
	}
	
	If name="" Quit $$$ERROR($$$InstallerParserError,"name",ptr,"EOF")
	
	Quit $$$OK
	
value(str,ptr,value)
	Kill value
	Set sc=$$strlit(str,.ptr,.value)
	Quit:$$$ISERR(sc) sc
	
	If '$D(value) {
		// Must be a notcomma loop
		Set sc=$$notchar(str,.ptr,",",.value)
	}
	
	Quit sc
	
notchar(str,ptr,char,seq)
#dim seq As %String
#dim char As %String
	Set seq=""
	While ((ptr'>$L(str)) && ($E(str,ptr)'=char)) {
		Set seq=seq_$E(str,ptr)
		$$$NEXT
	}
	
	Quit $$$OK
	
strlit(str,ptr,value)
	If '$$$ISTOK("""") {
		// Not a strlit ...
		Kill value
		Quit $$$OK
	} Else {
		Set value=""
	}
	
	$$$NEXT
	
	While (1) {
		Set sc=$$notchar(str,.ptr,"""",.seq)
		Quit:$$$ISERR(sc)
		
		If seq'="" {
			Set value=value_seq
		} ElseIf $$$ISTOK("""""") {
			// Doubled quote?
			Set value=value_""""
			$$$NEXT
			$$$NEXT
			
		} ElseIf $$$ISTOK("""") {
			// Single quote?
			Quit
		} Else {
			// Error!
			If ptr>$L(str) {
				Set sc=$$$ERROR($$$InstallerParserError,"strlit",ptr,"EOF")
			} Else {
				Set sc=$$$ERROR($$$InstallerParserError,"strlit",ptr,$E(str,ptr,*))
			}
			Quit
		}
	}
	
	Quit:$$$ISERR(sc) sc
	
	If '$$$ISTOK("""") {
		Set sc=$$$ERROR($$$InstallerParserError,"""",ptr,"EOF")
		Quit sc
	}
	
	$$$NEXT
	
	Quit $$$OK
}

}
