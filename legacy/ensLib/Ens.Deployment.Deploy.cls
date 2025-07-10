/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsDeploy

/// <class>Ens.Deployment.Deploy</class> provides an API to deploy code and settings changes to a production.  <br> <br>
/// <!doctype html public "-//w3c//dtd html 4.0 transitional//en">
/// <html>
/// <head>
///    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
///    <meta name="GENERATOR" content="Mozilla/4.77 [en] (Windows NT 5.0; U) [Netscape]">
///    <title>Dynamic SQL</title>
/// </head>
/// 	<body>
/// 	<h1>Deployment</h1>
/// 	<h2>Overview</h2>
/// 	
/// 	<p>This is the main class of methods for applying the deployment of code changes that have been exported from one production to another production.
/// 		</p>
/// 
/// 	<p>The primary deployment method is DeployCode() which is invoked from the portal or can be invoked from the command line: 
/// 		</p>
/// <pre>
/// Set tSC = ##class(Ens.Deployment.Deploy).DeployCode(DeploymentFile,TargetProduction,CreateRollback,RollbackFilename,WhereToLog,LogFile,AllowDeployToSource,AutoRevert) 
/// </pre>
/// 		<p>where</p>
/// 
/// <p>DeploymentFile is the name of file containing the export generated from the production portal.</p>
/// <p>TargetProduction is the name of the production to apply the changes to.</p>
/// <p>CreateRollback indicates if a rollback file is to be made. The default is true. If set to false the code checks that the rollback file specified by the next parameter exists.</p>
/// <p>RollbackFilename is the name of the file to create and use to rollback the changes.Deployment Files can be re-applied but rollback file names must be unique.</p>
/// <p>WhereToLog indicates the locations to log information during the deployment and can either be empty or a combination of: </p>
/// 		<pre>
/// 			L - Write to the file name specified in the LogFile parameter
/// 			C - write line text to current device
/// 			H - write HTML version of text to temporary global for retrieval by portal
/// 			EI - write text to event log Info
/// 
/// 			The start and finish of the deployment will always be written to the event log.
/// 		</pre>
/// <p>LogFile is the name of the file to log deployment information to. </p>
/// <p>AllowDeployToSource specifies if the deployment file can be applied to the same machine,instance and namespace as that where it was created. The default is to not allow except for applying a rollback file</p>
/// <p>AutoRevert specifies if the deployment ought to undo any changes made after it encounters an error during the deployment. The default is to auto revert on error.</p>
///  		 
Class Ens.Deployment.Deploy [ Abstract, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Deploy the code to the target production in the current namespace.
/// This method is called from the portal page and can be called independently. 
/// If called directly from a web page it is possible that this job can take longer
/// than the Gateway Server Timeout - hence calling via %RunBackgroundMethod is preferrable.
ClassMethod DeployCode(pDeploymentFile As %String = "", pTargetProduction As %String = "", pCreateRollback As %Integer = 1, pRollbackFilename As %String = "", pWhereToLog As %String = "", pLogFile As %String = "", pAllowDeployToSource As %Boolean = 0, pAutoRevert As %Boolean = 1, pTempPortalNode As %String = "") As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK,tWhereToLogError = $REPLACE(pWhereToLog,"EI","EE"),tCompletedSuccessfully = 0,tHaveTokens = 0 
	Set tDeploymentToken="",tDeploymentInvocation="",tSingleFailure = "",tRequiresManualIntervention="",tReverted=0
	Set tProductionClassLocked = 0
	
	$$$LOGINFO($$$Text("Starting deployment of file")_" "_pDeploymentFile_" to "_pTargetProduction)
	$$$SetDeployLogWhere(pWhereToLog)
	If $IsObject($get(%session)) { /* If called directly from a web page rather than via %RunBackgroundMethod */
		Do %session.Unlock()
		Set:(pTempPortalNode'="") %TempPortalNode = ##class(EnsPortal.SessionEvents).GetReference(##class(EnsPortal.SessionEvents).GetTempNode())	
	}
	Set:(pTempPortalNode'="") %TempPortalNode = pTempPortalNode /* Used for the logging in WriteDeployLog */
	If (pLogFile '= "") {
		If '##class(%File).DirectoryExists(##class(%File).GetDirectory(pLogFile)) {
			Set tInfo = $$$Text("Directory for Log file")_" "_##class(%File).GetDirectory(pLogFile)_" "_$$$Text("does not exist")
			$$$OutputDeployLog(tInfo)
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Goto Exit
		}
		$$$SetDeployLogFile(pLogFile)
		Set tInfo = $$$Text("Writing to Log File")_" "_pLogFile
		$$$OutputDeployLog(tInfo)
		If '##class(%File).Exists(pLogFile) {
			Set tInfo = $$$Text("Failed to create")_" "_$$$Text("Log file.")_" "_$$$Text("Possible permissions or legal filename restriction.")
			$$$OutputDeployLog(tInfo)
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Goto Exit
		}
	}
		
	If '$IsObject(pDeploymentFile) {	
		If '##class(%File).Exists(pDeploymentFile) {
			Set tInfo = $$$Text("Deployment file does not exist")_" "_pDeploymentFile
			$$$OutputDeployLog(tInfo)
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Goto Exit
		}
	} Else {
		Set tDeploymentFileFromInput = ##class(%Stream.FileBinary).%New()
		Set tDeploymentFileFromInput.Filename = ##class(%File).TempFilename("xml")
		Set tSC = tDeploymentFileFromInput.CopyFromAndSave(pDeploymentFile)
		Goto:$$$ISERR(tSC) Exit
		Set pDeploymentFile = tDeploymentFileFromInput.Filename /* reset DeploymentFile to just a file name */
		Set tDeploymentFileFromInput = ""
	}
		
	Set tSC = ..PreDeploymentTokenChecks(pDeploymentFile,pRollbackFilename,pCreateRollback,pAllowDeployToSource,.tDeploymentVDOC,.tDeploymentNotesVDOC,.tSourceInfo,.tTargetInfo)	
	Goto:$$$ISERR(tSC) Exit

	/* Ready to start the deployment. Open Token object - only one process can have this open */
	
	
	Set tDeploymentToken = ..GetDeploymentToken(.tSourceInfo,.tTargetInfo, .tSC)  
	Goto:$$$ISERR(tSC) Exit
		
	Set tDeploymentInvocation = ..InitDeploymentToken(.tDeploymentToken,pDeploymentFile,pTargetProduction,.tSC)  
	Goto:$$$ISERR(tSC) Exit
	
	Set tHaveTokens = 1
	
	/* Update tokens if Rollback */
	
	Set tSC = ..RecordIfRollback(pRollbackFilename,tDeploymentNotesVDOC,tDeploymentToken,tDeploymentInvocation,.tIsARollback)
	Goto:$$$ISERR(tSC) Exit
		
	/* If pTargetProduction is not defined up to here then GetProjectContents attempts to set. It returns an error if it cannot */	
	Set tSC = ..GetProjectContents(pDeploymentFile,tDeploymentVDOC,.pTargetProduction,.tDeployDetails) 
	Goto:$$$ISERR(tSC) Exit
		
	/* Check if the production is locked and lock if not for the duration of the deployment*/
	If ##class(%RoutineMgr).Exists(pTargetProduction_".CLS") {
		Set tSC = ##class(%Dictionary.CompiledClass).%LockId(pTargetProduction)
		If $$$ISERR(tSC) {
			Set tInfo = $$$Text("Failed to lock target Production Class at the start of deployment")_": "_pTargetProduction
			$$$OutputDeployLog(tInfo)
			$$$OutputDeployLog($$$StatusDisplayString(tSC))
			Goto Exit
		}
		Set tProductionClassLocked = 1
		Set tInfo = $$$Text("Locked target Production Class at the start of deployment")_": "_pTargetProduction
		$$$OutputDeployLog(tInfo)
	}
	
	
	If pCreateRollback {
		Set tInfo = $$$Text("Creating rollback file...")
		$$$OutputDeployLog(tInfo)
		Set tRollbackDescription = $$$Text("Deployment Rollback")
		Set tSC = ..MakePreDeploymentRollback(pDeploymentFile,pRollbackFilename,.tDeployDetails,"",tRollbackDescription) 
		Goto:$$$ISERR(tSC) Exit
	}

	Set tSC = ..GenerateListsFromProjectContents(.tDeployDetails,.tPTDToDelete,.tStandardOBJLoadList,.tHostItemsToRemove,.tObjectsToDelete)			
	Goto:$$$ISERR(tSC) Exit
	
	Set tSC = ..StoreFilesinInvocationObject(.tDeploymentInvocation, pDeploymentFile, pRollbackFilename)
	Goto:$$$ISERR(tSC) Exit
	
	/* Up to this point any failure will not involve changes to the production */

	If ##class(Ens.Util.SourceControl).IsEnabled() {
		Set tSC1 = ##class(Ens.Util.SourceControl).CreateSourceControl(.tSourceControl,.tCreated)
		If $$$ISOK(tSC1) && $get(tCreated) {
			New %SourceControl
			Set %SourceControl = tSourceControl
			Set tInfo=$$$Text("Using Source Control class")_": "_$Classname(tSourceControl)
			$$$OutputDeployLog(tInfo)
			Set tSC = ##class(Ens.Deployment.Utils).SourceControlGetStatus(.tDeployDetails,.tItemsAlreadyCheckedOut)
			Goto:$$$ISERR(tSC) Exit
			If tItemsAlreadyCheckedOut {
				Set tInfo = $$$Text("Item(s) in the deployment currently checked out. Stopping deployment.")
				Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
				Goto Exit
			}
		} Else {
			Set tInfo=$$$Text("Failed to initiate source control class")
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Set:$$$ISERR(tSC1) tSC = $$$ADDSC(tSC,tSC1)
			Goto Exit	
		}
	}
	
	Set tSC = ..ApplyDeploymentFile(.tDeploymentToken,.tDeploymentInvocation,pDeploymentFile,pRollbackFilename,pLogFile,pTargetProduction,.tDeployDetails,.tPTDToDelete,.tStandardOBJLoadList,.tHostItemsToRemove,.tObjectsToDelete,.tSingleFailure,.tRequiresManualIntervention,pAutoRevert,.tHadToTryRevert) 
	
	/* Single failure is the trigger for stopping deployment */
	If (tSingleFailure '= "") {
		/* Revert called on SingleFailure if AutoRevert set */
		Set:pAutoRevert tInfo = $$$Text("Attempted Revert to state prior to deployment") $$$OutputDeployLog(tInfo)
		Set tInfo = $$$Text("Deploying encountered an issue")_" "_tSingleFailure
		$$$OutputDeployLog(tInfo)
		If (tRequiresManualIntervention '= "") {
			Set tInfo = $$$Text("Reverting to state prior to deployment attempt requires manual intervention")_": "_tRequiresManualIntervention
			$$$OutputDeployLog(tInfo)
		} ElseIf pAutoRevert {
			Set tInfo = $$$Text("Revert to state prior to deployment successful")	
			$$$OutputDeployLog(tInfo)
			Set tReverted = 1
		}
	} ElseIf (tRequiresManualIntervention '= "") {
		Set tInfo = $$$Text("Deploying encountered an issue")_": "_tRequiresManualIntervention
		$$$OutputDeployLog(tInfo)		
	}
	If tSC && ((tSingleFailure '= "") || (tRequiresManualIntervention '= "")) Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)	
	
Exit
	Set $ZT = ""
	Try {
		If tProductionClassLocked {
			Do ##class(%Dictionary.CompiledClass).%UnlockId(pTargetProduction)
			Set tProductionClassLocked = 0
			Set tInfo = $$$Text("Unlocked target Production Class at the end of deployment")_": "_pTargetProduction
			$$$OutputDeployLog(tInfo)
		}
		If $$$ISERR(tSC) {
			Set tInfo = $$$Text("Failed to complete deployment of")_" "_$G(pDeploymentFile)
			$$$OutputDeployLog(tInfo)
			If tHaveTokens {
				Set tSC1 = ..RecordDeploymentInvocationError(.tDeploymentToken,.tDeploymentInvocation, tSC, tSingleFailure, tRequiresManualIntervention, tReverted)		
				If $$$ISERR(tSC1){$$$OutputDeployLog($$$StatusDisplayString(tSC1)) Set tSC = $$$ADDSC(tSC,tSC1)}
			}
		} Else {
			Set tInfo =$$$Text("Finished Deploying successfully") 
			$$$OutputDeployLog(tInfo)
			Set tCompletedSuccessfully = 1
			/* Call CheckIn for all that are checked out. Only if successful */
			Set tSC1 = ##class(Ens.Deployment.Utils).SourceControlCheckIn(.tDeployDetails)
			If $$$ISERR(tSC1){$$$OutputDeployLog($$$StatusDisplayString(tSC1))  Set tSC = $$$ADDSC(tSC,tSC1)}
		}
		If tHaveTokens {
			If tIsARollback {
				Set tSC1 = ..RecordEndOfRollback(.tDeploymentInvocation)
				If $$$ISERR(tSC1){$$$OutputDeployLog($$$StatusDisplayString(tSC1))  Set tSC = $$$ADDSC(tSC,tSC1)}
			}
			Set tSC1 = ..CloseDeploymentTokenAndInvocation(.tDeploymentToken,.tDeploymentInvocation,tCompletedSuccessfully,tReverted,pLogFile)
			If $$$ISERR(tSC1){$$$OutputDeployLog($$$StatusDisplayString(tSC1))  Set tSC = $$$ADDSC(tSC,tSC1)}
		}
		If ($$$ISERR(tSC) && ($$$StatusDisplayString(tSC)["ErrJobNotStopped")) {
			Set tInfo =$$$Text("If the deployment failed due to a failure to disable within the timeout consider increasing Update Timeout value in the Production Settings.")
			$$$OutputDeployLog(tInfo)
		}
		
		Set tDeploymentToken = ""
		Set tDeploymentInvocation  = ""
		If $IsObject($Get(%session)) {
			Do %session.Lock()
		}
		Set:($G(%TempPortalNode)'="") @%TempPortalNode@("Finished") = $H, @%TempPortalNode@("Status") = tSC
	 	$$$ClearDeployLog
		$$$LOGINFO($$$Text("Finished deployment of file")_" "_pDeploymentFile_" to "_pTargetProduction_" "_$$$Text("with status")_" "_$$$StatusDisplayString(tSC))
	} Catch ex { 
		Set tSC = ex.AsStatus()
		$$$LOGERROR($$$Text("Error during Exit of DeployCode()")_" "_$$$Text("with status")_" "_$$$StatusDisplayString(tSC))	
	}
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	Goto Exit
}

/// Generate XML VDoc Deployment File by converting a Deployment file to an XML VDoc
ClassMethod GeneratePackageXMLVDOC(pDeploymentFile As %String, Output pDeploymentVDOC As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	$$$OutputDeployLog($$$Text("Reading Deployment File")_" "_pDeploymentFile)
	Try {
		Set pDeploymentVDOC = ##class(EnsLib.EDI.XML.Document).%New(pDeploymentFile)
	}  Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set:(tSC && '$IsObject(pDeploymentVDOC)) tSC = $$$ERROR($$$EnsErrGeneral,$$$Text("Invalid deployment file"))
	Quit tSC
}

/// Generate an XML VDOC for a ProjectTextDocument in the DeploymentDOC. 
/// Pass in DeploymentVDOC and the PTD Name being searched for. Uses regular expression for the name.
/// Returns a VDOC. If error then GetValueAt("/1/name()") = "Error"
ClassMethod GeneratePTDXMLVDOC(pDeploymentFile As %String, pDeploymentVDOC As %RegisteredObject, pPTDNameWanted As %String, Output pPTDVDOC As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	$$$OutputDeployLog($$$Text("Getting Document")_" "_pPTDNameWanted)
	Try {
		Set pPTDVDOC = $$$NULLOREF
		Set tCount = pDeploymentVDOC.GetValueAt("/Export/Document[*]")
		For tPos = 1:1:tCount {
			Set tPosPTDName = pDeploymentVDOC.GetValueAt("/Export/Document["_tPos_"]/@name")
			Try {Set tPosPTDName=$ZCVT(tPosPTDName,"I","XML")} Catch {}
			If (tPosPTDName[pPTDNameWanted) {
					Set tPTDText = pDeploymentVDOC.GetValueAt("/Export/Document["_tPos_"]/")
					/* PTD Text is wrapped in CDATA so pDeploymentVDOC.GetValueAt("/Export/Document["_tPos_"]/1") will be converted to  "&lt;" so need to load the PTD) 
						Set tPTDText = $ZCVT(tPTDText,"I","XML")
						Set pPTDVDOC = ##class(EnsLib.EDI.XML.Document).%New(tPTDText)
					*/
					Set tPTDExistedBefore = ##class(%RoutineMgr).Exists(tPosPTDName)
					Set tSC = $system.OBJ.Load(pDeploymentFile,"-c-d",.err,.l,0,tPosPTDName)
					Quit:$$$ISERR(tSC)
					Set tSC=##class(Ens.Util.ProjectTextDocument).GetStream(.tStream,tPosPTDName,.tDesc)
					Set pPTDVDOC = ##class(EnsLib.EDI.XML.Document).%New(tStream)  
					If 'tPTDExistedBefore Do ##class(%RoutineMgr).Delete(tPosPTDName)
					Quit
				}
		}
		If (pPTDVDOC = "") Set pPTDVDOC=##class(EnsLib.EDI.XML.Document).%New("<Error>"_pPTDNameWanted_" not found.</Error>")
	} Catch ex {
		Set pPTDVDOC=##class(EnsLib.EDI.XML.Document).%New("<Error>"_ex.DisplayString()_".</Error>")
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find contents of the Deployment file and also find new items and populate in pDeployDetails("Remove")
/// If the Target Production name is not specified and the target cannot be identified in the source 
/// then the current active production in the namespace will be used. If a production has not been run
/// in the current namespace then this method returns an error of "Cannot identify a target production"
ClassMethod GetProjectContents(pDeploymentFile As %String, pDeploymentVDOC As %RegisteredObject, ByRef pTargetProductionName As %String = "", Output pDeployDetails) As %Status
{
	Set tSC = $$$OK
	Kill pDeployDetails
	$$$OutputDeployLog($$$Text("Generating Contents from Deployment File"))
	Set tProductionId = ""
	Set tSC = ..GeneratePTDXMLVDOC(pDeploymentFile,pDeploymentVDOC,"EnsExportNotes",.tDeploymentNotesVDOC)
	Quit:$$$ISERR(tSC) tSC
	Set tProductionClassInExport = tDeploymentNotesVDOC.GetValueAt("/Deployment/ProductionClassInExport")           
	Set tSourceProduction = tDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/SourceProduction")	
	If (tProductionClassInExport '= "" ) {
		Set tProductionId = tProductionClassInExport, pTargetProductionName = tProductionClassInExport
	} Else {
		Set:((pTargetProductionName = "") && ##class(Ens.Config.Production).%ExistsId(tSourceProduction)) pTargetProductionName = tSourceProduction
	}
	If (pTargetProductionName = "") Set pTargetProductionName = ##class(Ens.Director).GetActiveProductionName()

	If (pTargetProductionName = "") {
		Set tInfo = $$$Text("Cannot identify a target production")
		$$$OutputDeployLog(tInfo)
		Set tSC =  $$$ERROR($$$EnsErrGeneral,tInfo)
		Quit tSC		
	}
	Set tSC = ..RecordBasicContentsInfo(pDeploymentVDOC, .pDeployDetails) 
	Quit:($$$ISERR(tSC)) tSC

	Set:((tProductionClassInExport '= "") && $D(pDeployDetails("Items",tProductionClassInExport_".CLS"))) pDeployDetails("Items",tProductionClassInExport_".CLS","ItemIsProductionClass") = 1

	Set tSC = ..RecordContentsInfoRelativeToTarget(pDeploymentFile,pDeploymentVDOC,pTargetProductionName,.pDeployDetails) 
	Quit:($$$ISERR(tSC)) tSC

	Set tSC = ..BuildContentsListToRemove(pDeploymentFile,pDeploymentVDOC,pTargetProductionName,.pDeployDetails)
	Quit tSC
}

/// Go through XML file and record the locations in the array pDeployDetails
/// This will create pDeployDetails and also calculate extension based on type
/// and generate the unique ItemName.
ClassMethod RecordBasicContentsInfo(pDeploymentVDOC As %RegisteredObject, Output pDeployDetails) As %Status
{
	Set tSC = $$$OK, tRemoveLocation = ""
	Set tExtConversion("Class")="CLS"
	Set tExtConversion("Project")="PRJ"
	Set tExtConversion("INC")="INC"
	Set tExtConversion("MAC")="MAC"
	Set tExtConversion("INT")="INT"
	Kill pDeployDetails
	Try {
		Set tExportCount = pDeploymentVDOC.GetValueAt("/Export/*")
		For tCount = 1:1:tExportCount {
			Set tItemExportName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@name")
			Set tItemType = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@type")
			Set tItemDescription =  pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/Description")
			/* Type attribute can be used to add extension or xml name() Need to look up to see if defined. */
			Set tExportNodeName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/name()")
			Set:(tItemType = "") tItemType = tExportNodeName
			
			Set tItemCalculatedExtension = $G(tExtConversion(tItemType))
			If tItemCalculatedExtension '= "" {
				Set tItemName = tItemExportName_"."_tItemCalculatedExtension
			} Else { /* Extension already in the name */ 
				Set tItemName = tItemExportName
			}
			If tItemType = "CSP" {
				Set tCSPApplication = $system.CSP.GetDefaultApp($NAMESPACE) 
				Set:$E(tCSPApplication,1,1)="/" tCSPApplication = $E(tCSPApplication,2,*)
				Set tItemName = tCSPApplication_"/"_tItemName
			}
			If ((tItemType="Document") && ($P(tItemName,":")="Settings")) {
				Try {Set tItemName = $ZCVT(tItemName,"I","XML")} Catch {}
			}
			If tItemName = "" {
				/* Need to check for those exports that have no name */
				If tExportNodeName = "Global" {
					Set tItemCalculatedExtension = "GBL"
					/* e.g. ^Ens.LookupTable(&quot;Patient&quot;).GBL */
					Set tItemName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/Node/Sub")_"."_tItemCalculatedExtension
					/* Any subscript quotes will have been escaped when exported originally. */
					Set tItemName = $ZCVT(tItemName,"I","XML")
					Set tItemExportName = tItemName /* leave leading ^ */
					Set:($E(tItemName)="^") tItemName = $E(tItemName,2,*)
				}	
				Quit:(tItemName = "") /* skip if can't identify */
			}
			
			/* Used in UI */
			Set pDeployDetails("Items",tItemName,"ExportFileLocation") = tCount
			Set pDeployDetails("Items",tItemName,"ExportName") = tItemExportName
			Set pDeployDetails("Items",tItemName,"ExportType") = tItemType
			Set pDeployDetails("Items",tItemName,"Description") = tItemDescription		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// For each item listed in pDeployDetails examine if the item is in the target production
ClassMethod RecordContentsInfoRelativeToTarget(pDeploymentFile As %String, pDeploymentVDOC As %RegisteredObject, pTargetProductionName As %String = "", ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tItemName = $O(pDeployDetails("Items",""))
		While (tItemName '= "") {
			Set tItemType = $G(pDeployDetails("Items",tItemName,"ExportConvertedType"),$P(tItemName,".",$L(tItemName,".")))
			Set tItemExistDate = ##class(%RoutineMgr).GetDate(tItemName) /* if -1 then does not exist */
			Set tItemAlreadyInProduction = 0,tItemIsSettings=0,tConfigItemName="" 
			If (tItemType = "PTD") {
				If ($E(tItemName,1,9) = "Settings:") {
					If ##class(Ens.Config.Production).%ExistsId(pTargetProductionName) {
						Set tConfigItemName = $P($E(tItemName,10,*),".PTD",1)
						Set tItemIsSettings = 1
						Set tProduction = ##class(Ens.Config.Production).%OpenId(pTargetProductionName,,.tSC)
						If '$IsObject(tProduction) {
							$$$OutputDeployLog($$$Text("Cannot open target production")_" "_pTargetProductionName)
							Quit
						}
						Set tConfigItem = ##class(Ens.Config.Production).OpenItemByConfigName(pTargetProductionName_"||"_tConfigItemName,.tSC)
						Set tItemAlreadyInProduction = 0
						If tSC {
							If $IsObject(tConfigItem) {
								Set tItemAlreadyInProduction = 1
								Set pDeployDetails("Items",tItemName,"PoolSize") = tConfigItem.PoolSize
								Set tSC = ..GeneratePTDXMLVDOC(pDeploymentFile,pDeploymentVDOC,tItemName,.tPTDVDOC)
								Quit:($$$ISERR(tSC))
								Set tReader = ##class(%XML.Reader).%New() 
								Set tSC=tReader.OpenString(tPTDVDOC.GetValueAt("/")) quit:'(tSC)
								Do tReader.Correlate("Item","Ens.Config.Item")
								Set tLoaded = tReader.Next(.pItem,.tSC)  ;Expect 1
								If (tSC && tLoaded) {
									/* pItem is the proposed new item and tConfigItem is the existing */
									Set tSC = ..CompareItems(tConfigItem,pItem,.tItem1SettingChanges)
									Set tConfigItem = "",pItem = "" /* don't need open */
									If $$$ISERR(tSC) {
										Set tInfo = $$$Text("Failed to compare existing item with proposed changes")_" "_tConfigItemName
										$$$OutputDeployLog(tInfo)
										Set tSC =  $$$ERROR($$$EnsErrGeneral,tInfo)
										Quit	
									}
									Merge pDeployDetails("Items",tItemName,"CompareItemSettingChanges") = tItem1SettingChanges(tConfigItemName)
									Set tChangeAction = $O(tItem1SettingChanges(tConfigItemName,""))
									While (tChangeAction '= "") {
										Set tChangePropOrSettingName = $O(tItem1SettingChanges(tConfigItemName,tChangeAction,""))
										While (tChangePropOrSettingName '= "") {
											If (tChangeAction = "ChangeProperty") {
												Set pDeployDetails("Items",tItemName,"ReportDifferences",$I(pDeployDetails("Items",tItemName,"ReportDifferences")))=$$$Text("Property")_" "_tChangePropOrSettingName_" "_$$$Text("to be changed from")_" "_$G(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName,"Current"))_" "_$$$Text("to")_" "_$G(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName,"Deploy"))
											} Else {/*Setting*/
												Set tSettingTarget = $O(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName,""))
												While (tSettingTarget '= "") {
													/* ChangeSetting,AddSetting,RemoveSetting*/
													If (tChangeAction = "RemoveSetting") {
														Set pDeployDetails("Items",tItemName,"ReportDifferences",$I(pDeployDetails("Items",tItemName,"ReportDifferences")))=$$$Text("Setting")_" "_tChangePropOrSettingName_" ("_tSettingTarget_")"_" "_$$$Text("to be removed")
													} ElseIf (tChangeAction = "AddSetting"){
														Set pDeployDetails("Items",tItemName,"ReportDifferences",$I(pDeployDetails("Items",tItemName,"ReportDifferences")))=$$$Text("Setting")_" "_tChangePropOrSettingName_" ("_tSettingTarget_")"_" "_$$$Text("to be added with value")_" "_$G(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName,tSettingTarget))
													} ElseIf (tChangeAction = "ChangeSetting") {
														Set pDeployDetails("Items",tItemName,"ReportDifferences",$I(pDeployDetails("Items",tItemName,"ReportDifferences")))=$$$Text("Setting")_" "_tChangePropOrSettingName_" ("_tSettingTarget_")"_" "_$$$Text("to be changed from")_" "_$G(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName,tSettingTarget,"Current"))_" "_"to"_" "_$G(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName,tSettingTarget,"Deploy"))
													}
													Set tSettingTarget = $O(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName,tSettingTarget))
												} 
											}				
											Set tChangePropOrSettingName = $O(tItem1SettingChanges(tConfigItemName,tChangeAction,tChangePropOrSettingName))
										}
										Set tChangeAction = $O(tItem1SettingChanges(tConfigItemName,tChangeAction))
									}
									Set:'$D(pDeployDetails("Items",tItemName,"ReportDifferences")) pDeployDetails("Items",tItemName,"ReportDifferences")=1,pDeployDetails("Items",tItemName,"ReportDifferences",1)=$$$Text("No changes to current item settings.")
								} Else {
									Set tInfo = $$$Text("Failed to correlate item")_" "_tItemName
									$$$OutputDeployLog(tInfo)
									Set tSC =  $$$ERROR($$$EnsErrGeneral,tInfo)
									Quit
								}
							}
						} Else {
							Set:($$$StatusDisplayString(tSC)[$$$EnsErrConfigItemNotFound) tSC=$$$OK
							Quit:$$$ISERR(tSC)
						}
						$$$OutputDeployLog($$$Text("Found in deployment package settings for")_" "_$S(tItemAlreadyInProduction:$$$Text("existing"),1:$$$Text("new"))_" "_$$$Text("host item")_" "_tConfigItemName)
					} Else {
						/* Item Settings added to package before production created so remove */
						$$$OutputDeployLog($$$Text("Found in deployment package settings for")_" "_tItemName_" "_$$$Text("but target production does not exist and so will skip."))
						Kill pDeployDetails("Items",tItemName)
					}
				} ElseIf ($E(tItemName,1,19) = "ProductionSettings:") { /* If Settings: */
					If ##class(Ens.Config.Production).%ExistsId(pTargetProductionName) {
						Set tSC = ..RecordProductionSettingsChanges(pDeploymentFile,pDeploymentVDOC,pTargetProductionName,tItemName,.pDeployDetails)
						Set tItemExistDate = ##class(%RoutineMgr).GetDate(pTargetProductionName_".cls")
						Set tItemAlreadyInProduction = 1
						Quit:$$$ISERR(tSC)
					} Else {
						/*Production Settings added to package before production created so remove */
						$$$OutputDeployLog($$$Text("Found in deployment production settings for production")_" "_pTargetProductionName_" "_$$$Text("but target production does not exist and so will skip."))
						Kill pDeployDetails("Items",tItemName)
					}
				} Else {
					/* General PTD */
					Set pDeployDetails("Items",tItemName,"GeneralPTD")=1
				}
			} Else { /* If PTD */
				$$$OutputDeployLog($$$Text("Found in deployment package")_" "_$S(tItemExistDate=-1:$$$Text("new"),1:$$$Text("existing"))_" "_tItemName)
			}
			If $D(pDeployDetails("Items",tItemName)) {
				Set pDeployDetails("Items",tItemName) = ""
				Set pDeployDetails("Items",tItemName,"Type") = $G(tItemType)
				Set pDeployDetails("Items",tItemName,"ExistDate") = $G(tItemExistDate,-1)
				Set pDeployDetails("Items",tItemName,"ItemIsSettings") = $G(tItemIsSettings,0)
				Set pDeployDetails("Items",tItemName,"ItemProductionTarget") = pTargetProductionName
				Set pDeployDetails("Items",tItemName,"ConfigItemName") = $G(tConfigItemName)
				Set pDeployDetails("Items",tItemName,"ItemAlreadyInProduction") = $G(tItemAlreadyInProduction)
				If ((tItemIsSettings) && (tConfigItemName '= "")) {
					Set pDeployDetails("Items",tItemName,"ConfigBusinessType") = $G($$$ConfigBusinessType(tConfigItemName),-1)
					Set pDeployDetails("ItemsByBusinessType",$G($$$ConfigBusinessType(tConfigItemName),-1),tItemName) = ""
				} 
			}		
			Set tItemName = $O(pDeployDetails("Items",tItemName))
		}
	} Catch ex { Set tSC = ex.AsStatus()}
	Quit tSC
}

/// Retrieve production setting changes relative to a ProductionSettings project text document in
/// the deployment file.
ClassMethod RecordProductionSettingsChanges(pDeploymentFile As %String, pDeploymentVDOC As %RegisteredObject, pTargetProductionName, pItemName As %String, ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK
	Try {	
		Set tSC = ..GeneratePTDXMLVDOC(pDeploymentFile,pDeploymentVDOC,pItemName,.tPTDVDOC)
		Quit:($$$ISERR(tSC))
		Set pDeployDetails("Items",pItemName,"ProdSettings") = 1
		Set pDeployDetails("ProductionSettings") = pItemName
		Set tSettingsCount = tPTDVDOC.GetValueAt("/Production/Setting[*]")
		If tSettingsCount = "" {
			Set tSettingsCount = 0	
		} Else {
			For tC = 1:1:tSettingsCount {
				Set tTarget = tPTDVDOC.GetValueAt("/Production/Setting["_tC_"]/@Target")		
				Set tName = tPTDVDOC.GetValueAt("/Production/Setting["_tC_"]/@Name")		
				Set tValue = tPTDVDOC.GetValueAt("/Production/Setting["_tC_"]")		
				Set pDeployDetails("Items",pItemName,"ProdSettings","Settings",tC)=$LB(tTarget,tName,tValue)							
				Set tTempDeploySettings(tTarget_"||"_tName) = tValue
			}
		}
		Set pDeployDetails("Items",pItemName,"ProdSettings","Settings")=tSettingsCount
		Set tDescription = tPTDVDOC.GetValueAt("/Production/Description")
		Set tActorPoolSize = tPTDVDOC.GetValueAt("/Production/ActorPoolSize")
		Set:(tActorPoolSize = "") tActorPoolSize = $$$defMemberKeyGet("Ens.Config.Production",$$$cCLASSproperty,"ActorPoolSize",$$$cPROPinitialexpression)
		Set tTestingEnabled = tPTDVDOC.GetValueAt("/Production/@TestingEnabled")
		Set tTestingEnabled = $S(tTestingEnabled="true":1,tTestingEnabled="false":0,1:"")
		Set tLogGeneralTraceEvents = tPTDVDOC.GetValueAt("/Production/@LogGeneralTraceEvents")
		Set tLogGeneralTraceEvents = $S(tLogGeneralTraceEvents="true":1,tLogGeneralTraceEvents="false":0,1:"")
		Set:(tLogGeneralTraceEvents = "") tLogGeneralTraceEvents = $$$defMemberKeyGet("Ens.Config.Production",$$$cCLASSproperty,"LogGeneralTraceEvents",$$$cPROPinitialexpression)
		Set pDeployDetails("Items",pItemName,"ProdSettings","Description") = tDescription
		Set pDeployDetails("Items",pItemName,"ProdSettings","ActorPoolSize") = tActorPoolSize
		Set pDeployDetails("Items",pItemName,"ProdSettings","TestingEnabled") = tTestingEnabled
		Set pDeployDetails("Items",pItemName,"ProdSettings","LogGeneralTraceEvents") = tLogGeneralTraceEvents
		Set tSC = ..RecordCurrentProductionSettings(pTargetProductionName,.pDeployDetails)
		If ($G(pDeployDetails("ProductionSettings","Current","Description")) '= tDescription) {
			Set tCurrentValue = $G(pDeployDetails("ProductionSettings","Current","Description"))
			Set tDifference = $$$Text("Production")_" "_$$$Text("Description")_" "_$$$Text("changing from")_" "_$S(tCurrentValue="":$$$Text("Default value"),1:tCurrentValue)_" "_$$$Text("to")_" "_$S(tDescription="":"''",1:tDescription)
			Set pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) = tDifference
		}
		If +($G(pDeployDetails("ProductionSettings","Current","ActorPoolSize")) '= +tActorPoolSize) {
			Set tCurrentValue = $G(pDeployDetails("ProductionSettings","Current","ActorPoolSize"))
			Set tDifference = $$$Text("Production")_" "_$$$Text("ActorPoolSize")_" "_$$$Text("changing from")_" "_$S(tCurrentValue="":$$$Text("Default value"),1:tCurrentValue)_" "_$$$Text("to")_" "_$S(tActorPoolSize="":$$$Text("Default value"),1:tActorPoolSize)
			Set pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) = tDifference
		}
		If ($G(pDeployDetails("ProductionSettings","Current","TestingEnabled")) '= tTestingEnabled) {
			Set tCurrentValue = $G(pDeployDetails("ProductionSettings","Current","TestingEnabled"))
			Set tDifference = $$$Text("Production")_" "_$$$Text("TestingEnabled")_" "_$$$Text("changing from")_" "_$S(tCurrentValue="":$$$Text("Default value"),1:tCurrentValue)_" "_$$$Text("to")_" "_$S(tTestingEnabled="":$$$Text("Default value"),1:tTestingEnabled)
			Set pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) = tDifference
		}
		If ($G(pDeployDetails("ProductionSettings","Current","LogGeneralTraceEvents")) '= tLogGeneralTraceEvents) {
			Set tCurrentValue = $G(pDeployDetails("ProductionSettings","Current","LogGeneralTraceEvents"))
			Set tDifference = $$$Text("Production")_" "_$$$Text("LogGeneralTraceEvents")_" "_$$$Text("changing from")_" "_$S(tCurrentValue="":$$$Text("Default value"),1:tCurrentValue)_" "_$$$Text("to")_" "_$S(tLogGeneralTraceEvents="":$$$Text("Default value"),1:tLogGeneralTraceEvents)
			Set pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) = tDifference
		}
		Set tSettingsCount = $G(pDeployDetails("ProductionSettings","Current","Settings"),0)
		For tC = 1:1:tSettingsCount {
			Set tCurrentTarget = $LI($G(pDeployDetails("ProductionSettings","Current","Settings",tC)),1)
			Set tCurrentName = $LI($G(pDeployDetails("ProductionSettings","Current","Settings",tC)),2)
			Set tCurrentValue = $LI($G(pDeployDetails("ProductionSettings","Current","Settings",tC)),3)
			Kill tValue
			If '$D(tTempDeploySettings(tCurrentTarget_"||"_tCurrentName),tValue) {
				Set tDifference = $$$Text("Production Setting")_" "_tCurrentName_" "_$$$Text("being removed (set to default value)")
				Set pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) = tDifference	
			} Else {
				If (tCurrentValue '= tValue) {
					Set tDifference = $$$Text("Production Setting")_" "_tCurrentName_" "_$$$Text("changing from")_" "_tCurrentValue_" "_$$$Text("to")_" "_tValue
					Set pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) = tDifference	
				}
				Kill tTempDeploySettings(tCurrentTarget_"||"_tCurrentName)	
			}	
		}
		Set tSetting = $O(tTempDeploySettings(""))
		While (tSetting '= "") {	
			Set tDifference = $$$Text("Production Setting")_" "_$P(tSetting,"||",2)_" "_$$$Text("being changed from default value to")_" "_tTempDeploySettings(tSetting)
			Set pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) = tDifference	
			Set tSetting = $O(tTempDeploySettings(tSetting))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set:'$G(pDeployDetails("Items",pItemName,"ReportDifferences")) pDeployDetails("Items",pItemName,"ReportDifferences",$I(pDeployDetails("Items",pItemName,"ReportDifferences"))) =$$$Text("No changes to production settings.")
	Quit tSC
}

/// Save current production settings
ClassMethod RecordCurrentProductionSettings(pTargetProductionName, ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK
	Try {	
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pTargetProductionName,,.tSC)
		If $$$ISERR(tSC) || '$IsObject(tProduction) {
			Set tInfo = $$$Text("Failed to open production")_" "_pTargetProductionName_" : "_$$$StatusDisplayString(tSC)
			$$$OutputDeployLog(tInfo)
			Set tSC=$$$ERROR($$$EnsErrGeneral,tInfo)
			Quit
		}
		Set pDeployDetails("ProductionSettings","Current","Description") = tProduction.Description
		Set pDeployDetails("ProductionSettings","Current","ActorPoolSize") = tProduction.ActorPoolSize
		Set pDeployDetails("ProductionSettings","Current","TestingEnabled") = tProduction.TestingEnabled
		Set pDeployDetails("ProductionSettings","Current","LogGeneralTraceEvents") = tProduction.LogGeneralTraceEvents
		Set tSettingsCount = tProduction.Settings.Count()
		Set pDeployDetails("ProductionSettings","Current","Settings") = tSettingsCount
		For tC = 1:1:tSettingsCount {
			Set tSetting = tProduction.Settings.GetAt(tC)
			Set pDeployDetails("ProductionSettings","Current","Settings",tC) = $LB(tSetting.Target,tSetting.Name,tSetting.Value)
			Do tProduction.Settings.%UnSwizzleAt(tC)
		}			
	} Catch ex {
		Set tSC = ex.AsStatus()
	}	
	Quit tSC
}

/// Convert Export Remove Project Document to array.
ClassMethod BuildContentsListToRemove(pDeploymentFile As %String, pDeploymentVDOC As %RegisteredObject, pTargetProductionName As %String = "", ByRef pDeployDetails As %String) As %Status
{
	/*
		<Document name="EnsExportRemove.EnsExportRollback_2012-07-16 07:42:19_790-4.PTD">
		<ProjectTextDocument name="EnsExportRemove.EnsExportRollback_2012-07-16 07:42:19_790-4" description="List of items to delete EnsExportRollback_2012-07-16 07:42:19_790-4">
		<![CDATA[
		<DeploymentRemoval>
		<DeploymentFile>C:\InterSystems\Ens131\mgr\Rollback_before_ExportItem-Scratch_NewProduction_bsTCPStatus-20120716074132.xml</DeploymentFile>
		<Creation>
			<Machine>MACKEITHDEV</Machine>
			<Instance>ENS131</Instance>
			<Namespace>LIVE</Namespace>
			<SourceProduction>Scratch.NewProduction</SourceProduction>
			<Username>_SYSTEM</Username>
			<UTC>2012-07-16 11:42:19.790</UTC>
		</Creation>
		<ItemsToDelete>
			<Item num="1">EnsExportNotes.EnsExportItem_2012-07-16 07:41:32_806-4.PTD</Item>
			<Item num="2">Settings:bsTCPStatus.PTD</Item>
		</ItemsToDelete>
		</DeploymentRemoval>
		]]>
		</ProjectTextDocument>
			
	*/
	Try {
		Kill pDeployDetails("Remove")
		Set tSC = ..GeneratePTDXMLVDOC(pDeploymentFile,pDeploymentVDOC,"EnsExportRemove",.pDeploymentRemoveVDOC)
		Quit:$$$ISERR(tSC)
		Set tCountItems = pDeploymentRemoveVDOC.GetValueAt("/DeploymentRemoval/ItemsToDelete/*")
		For tC = 1:1:tCountItems {
			Set tItemName = pDeploymentRemoveVDOC.GetValueAt("/DeploymentRemoval/ItemsToDelete/"_tC)
			Set tLastDot = $LENGTH(tItemName)+2-$FIND($REVERSE(tItemName),".")
			Set tItemNameRootAndDot = $E(tItemName,1,tLastDot)
			Set tItemType = $E(tItemName,tLastDot+1,*)
			Set pDeployDetails("Remove",tItemName)=""
			Set pDeployDetails("Remove",tItemName,"Type") = tItemType
			Set tConfigItemName = ""
			Set tItemIsSettings = 0	
			If ((tItemType = "PTD") && ($E(tItemName,1,9) = "Settings:")) {
				Set tConfigItemName = $P($E(tItemName,10,*),".PTD",1)
				Set tItemIsSettings = 1
			}
			Set pDeployDetails("Remove",tItemName,"ItemIsSettings") = tItemIsSettings
			Set pDeployDetails("Remove",tItemName,"ItemProductionTarget") = pTargetProductionName
			Set pDeployDetails("Remove",tItemName,"ConfigItemName") = tConfigItemName
		}
	} Catch ex { Set tSC = ex.AsStatus()}
	Quit tSC
}

/// Separate production items from code
ClassMethod GenerateListsFromProjectContents(ByRef pDeployDetails As %String, Output pPTDToDelete, Output pStandardOBJLoadList, Output pHostItemsToRemove As %String, Output pObjectsToDelete As %String) As %Status
{
	/*			
			1. Create list of PTD that need to be deleted after. Settings PTD files: pPTDToDelete()
			2. Create list of contents to be loaded by $SYSTEM.OBJ.Load. Load everything except PRJ. Used to validate against what is loaded: pStandardOBJLoadList()
			3. Create list of host items to be Removed: pHostItemsToRemove()
			4. Create list of code to be deleted using ##class(%RoutineMgr).Delete of the the items in pObjectsToDelete()
	*/
	Set tSC = $$$OK 
	Try {
		Set tItemName = $O(pDeployDetails("Items",""))
		While (tItemName '= "") {
			Set tItemType = $G(pDeployDetails("Items",tItemName,"Type"))
			Set tItemExistDate = $G(pDeployDetails("Items",tItemName,"ExistDate"),-1) 
			Set tItemIsProductionClass = $G(pDeployDetails("Items",tItemName,"ItemIsProductionClass"),0) 
			Set tItemIsSettings = $G(pDeployDetails("Items",tItemName,"ItemIsSettings"),0) 
			Set tProductionId = $G(pDeployDetails("Items",tItemName,"ItemProductionTarget")) 
			Set tConfigItemName = $G(pDeployDetails("Items",tItemName,"ConfigItemName")) 
			Set tItemIsProductionsSettings = ($G(pDeployDetails("ProductionSettings")) = tItemName)
			Set tItemAlreadyInProduction = $G(pDeployDetails("Items",tItemName,"ItemAlreadyInProduction"),0)
			
			Set:(tItemType '= "PRJ") pStandardOBJLoadList(tItemName) = ""
			If (tItemIsSettings || tItemIsProductionsSettings ){
				Set pPTDToDelete(tItemName) = ""
				$$$OutputDeployLog($$$Text("Will import item settings for")_" "_$S(tItemAlreadyInProduction:$$$Text("existing"),1:$$$Text("new"))_" "_tConfigItemName)
			} Else {
				$$$OutputDeployLog($$$Text("Will import")_" "_$S(tItemExistDate=-1:$$$Text("new"),1:$$$Text("existing"))_" "_tItemName)
				Set:(($E(tItemName,1,14) = "EnsExportNotes") || ($E(tItemName,1,15) = "EnsExportRemove")) pPTDToDelete(tItemName) = ""
			}			
			Set tItemName = $O(pDeployDetails("Items",tItemName))
		}

		Set tItemName = $O(pDeployDetails("Remove",""))
		Set tCount = 0
		While (tItemName '= "") {
			Set tCount = tCount + 1
			Set tItemType = $G(pDeployDetails("Remove",tItemName,"Type"))
			If ("Settings:" = $E(tItemName,1,9)) {
				Set tOneHostItemToRemove = $P($P(tItemName,"Settings:",2),".PTD")
				If (tOneHostItemToRemove '= "") {Set pHostItemsToRemove(tOneHostItemToRemove)="" $$$OutputDeployLog($$$Text("Will delete host item")_" "_tConfigItemName)}
 			} Else {
				If (##class(%RoutineMgr).GetDate(tItemName)'=-1) {Set pObjectsToDelete(tItemName)="" $$$OutputDeployLog($$$Text("Will delete code")_" "_tItemName)}
			}
			Set tItemName = $O(pDeployDetails("Remove",tItemName))
		}
	} Catch ex { Set tSC = ex.AsStatus()}
	Quit tSC
}

/// Apply the Deployment file to the target production based upon pDeployDetails and ItemsToRemove
ClassMethod ApplyDeploymentFile(ByRef pDeploymentToken, ByRef pDeploymentInvocation, pFilename As %String, pRollbackFilename As %String, pLogFile As %String, pTargetProduction As %String = "", ByRef pDeployDetails, ByRef pPTDToDelete, ByRef pStandardOBJLoadList, ByRef pHostItemsToRemove, ByRef pObjectsToDelete, Output pSingleFailure As %String = "", Output pRequiresManualIntervention As %String = "", pAutoRevert As %Boolean = 1, Output pHadToTryRevert = 0) As %Status
{
	Set tSC = $$$OK,tSC1=$$$OK
	Set tSC = ..RecordStartDeploymentToken(.pDeploymentToken,.pDeploymentInvocation,pTargetProduction,pFilename,pRollbackFilename,pLogFile,pAutoRevert)
	If $$$ISERR(tSC) Goto ptdcleanup
	Set pDeployDetails("InvocationId") = pDeploymentInvocation.%Id()
	
	Set tInfo = $$$Text("Checking if UpdateProduction needs to be called before starting deployment.")
	$$$OutputDeployLog(tInfo)
	Set tSC = ..UpdateProduction()
	If $$$ISERR(tSC) Goto ptdcleanup
	
	Set tInfo = $$$Text("Applying deployment file...")
	$$$OutputDeployLog(tInfo)
	
	Set tSC = ..DisableItemsBeforeDeployment(.pDeployDetails,.tItemsDisabled,.pSingleFailure,.pRequiresManualIntervention,pAutoRevert)
	If (($$$ISERR(tSC)) || 	(pSingleFailure'="") || (pRequiresManualIntervention '="")) {
		Goto ptdcleanup
	}
		
	Set tSC = ..LoadAndCompileCode(.pDeployDetails, pFilename,pRollbackFilename,.tErrors,.tLoadedList,.pStandardOBJLoadList,.pSingleFailure,.pRequiresManualIntervention,pAutoRevert)	
	If ((pRequiresManualIntervention '="") && pAutoRevert) Goto ptdcleanup
	If ((pSingleFailure'="")||($$$ISERR(tSC))) {
		If pAutoRevert Goto revertdisable	
		Goto ptdcleanup
	}
	
	Set tSC = ..MakeHostItemChanges(.tItemsInsertedId,.pDeployDetails,pTargetProduction,pFilename,pRollbackFilename,.pSingleFailure,.pRequiresManualIntervention,pAutoRevert)	
	If ((pRequiresManualIntervention '="") && pAutoRevert) Goto ptdcleanup
	If ((pSingleFailure'="")||($$$ISERR(tSC))) {
		If pAutoRevert Goto revertloadandcompile
		Goto ptdcleanup 
	}
	 
	Set tSC = ..RemoveItemsFromProduction(pTargetProduction, .pHostItemsToRemove, .tHostItemRemovedStream, pRollbackFilename, .pSingleFailure, .pRequiresManualIntervention, pAutoRevert)
	If ((pRequiresManualIntervention '="") && pAutoRevert) Goto ptdcleanup
	If ((pSingleFailure'="")||($$$ISERR(tSC))) {
		If pAutoRevert Goto reverthostchanges
		Goto ptdcleanup 
	}

	Set tSC = ..DeleteObjects(.pDeployDetails,.pObjectsToDelete, pRollbackFilename, .pSingleFailure, .pRequiresManualIntervention, pAutoRevert)
	If ((pRequiresManualIntervention '="") && pAutoRevert) Goto ptdcleanup
	If ((pSingleFailure'="")||($$$ISERR(tSC))) {
		If pAutoRevert Goto revertremoveitems
		Goto ptdcleanup
	}
	
	Set tSC = ..ChangeProductionSettings(pTargetProduction,.pDeployDetails)

reenable		
 	Set tSC = ..EnableDisabledItemsThatAreFlaggedEnabled(.pDeployDetails)	
	If $$$ISERR(tSC) {
		Set pRequiresManualIntervention = $$$Text("Errored Re-enabling production items at the end of deployment.")_" "_$$$StatusDisplayString(tSC)
		$$$OutputDeployLog(pRequiresManualIntervention) /* carrying on to update production class */
	}

savetoclass
	Set tSC = ..SaveToClass(pTargetProduction, .pDeployDetails)
	If $$$ISERR(tSC) {
		Set pRequiresManualIntervention = $$$Text("Errored executing SaveToClass for the production to update XDATA section at the end of deployment. Check Portal configuration.")
		Goto ptdcleanup
	}
updateproduction
	Set tSC = ..UpdateProduction()
	If $$$ISERR(tSC) {
		Set pRequiresManualIntervention = $$$Text("Errored Updating production at the end of deployment.")_" "_$$$StatusDisplayString(tSC)
		/* fall through to ptdcleanup */
	}
ptdcleanup
	Set tSC1 = ..PTDCleanup(.pPTDToDelete)
	If $$$ISERR(tSC1) {
		Set pRequiresManualIntervention = $G(pRequiresManualIntervention)_$$$Text("Errored removing temporary production text documents at the end of deployment.")
		Set tSC = $$$ADDSC(tSC1,tSC)
	}	
Exit
	Quit tSC

revertremoveitems
	Set tSC1 = ..RevertRemoveItemsFromProduction(.tHostItemRemovedStream, pRollbackFilename, pTargetProduction,.pRequiresManualIntervention)		
	Set:$$$ISERR(tSC1) tSC = $$$ADDSC(tSC,tSC1)
	If ((pRequiresManualIntervention '="") || $$$ISERR(tSC1)) goto ptdcleanup
	
reverthostchanges
	Set tSC1 = ..RevertMakeHostItemChanges(.tItemsInsertedId,.pDeployDetails,pRollbackFilename,pTargetProduction,.pRequiresManualIntervention)
	Set:$$$ISERR(tSC1) tSC = $$$ADDSC(tSC,tSC1)
	If ((pRequiresManualIntervention '="") || $$$ISERR(tSC1)) goto ptdcleanup
	
revertloadandcompile
	Set tSC1 = ..RevertLoadAndCompileCode(pRollbackFilename, .pStandardOBJLoadList, .pRequiresManualIntervention)
	Set:$$$ISERR(tSC1) tSC = $$$ADDSC(tSC,tSC1)
	If ((pRequiresManualIntervention '="") || $$$ISERR(tSC1)) goto ptdcleanup
			
revertdisable
	Set tSC1 = ..RevertDisableItemsBeforeDeployment(.tItemsDisabled, .pRequiresManualIntervention)
	Set:$$$ISERR(tSC1) tSC1 = $$$ADDSC(tSC,tSC1)
	goto ptdcleanup
}

/// Disable items that are to be changed. Record original state. 
/// Disable all business services first and then Business Processes and Operations.
/// Do not disable Business Processes which have an actor pool size = 0.
ClassMethod DisableItemsBeforeDeployment(pDeployDetails As %String, Output pItemsDisabled As %String, Output pSingleFailure As %String = "", Output pRequiresManualIntervention As %String = "", pAutoRevert As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try { 		
		Set tItemName = $O(pDeployDetails("Items",""))
		While (tItemName '= "") { 
			If ($G(pDeployDetails("Items",tItemName,"ItemAlreadyInProduction"))&&$G(pDeployDetails("Items",tItemName,"ItemIsSettings"))) {
				Set tProductionId = $G(pDeployDetails("Items",tItemName,"ItemProductionTarget")) 
				Set tConfigItemName = $G(pDeployDetails("Items",tItemName,"ConfigItemName")) 
				Set:((tProductionId'="")&&($L(tConfigItemName,"||")=1)) tConfigItemName = tProductionId_"||"_tConfigItemName /* prepend productionid_"||"_tConfigItemName */
				Do ##class(Ens.Director).ParseConfigItemName(tConfigItemName,.tProductionName,.tHostItemName,.tCommentOrClass)
				Set tIsEnabled = $G($$$ConfigIsEnabled(tHostItemName),0) /* assumes production is updated */
				Set pDeployDetails("Items",tItemName,"EnabledStatusAtDeploy")=tIsEnabled		
				If tIsEnabled {
					Set:((tProductionId'="")&&($L(tConfigItemName,"||")=1)) tConfigItemName = tProductionId_"||"_tConfigItemName /* prepend productionid_"||"_tConfigItemName */
					Set tConfigType = pDeployDetails("Items",tItemName,"ConfigBusinessType")
					If tConfigType = $$$eHostTypeService {
						Set tSC = ..DisableOneItem(tConfigItemName,tConfigType,.tIsStillEnabled,.pItemsDisabled) 
						If (tIsStillEnabled || $$$ISERR(tSC)) {
							Set pSingleFailure =  $$$Text("Failed to disable an item")
							Quit	
						}
					} 
					Set tOrderedByType($CASE(tConfigType,$$$eHostTypeService:1,$$$eHostTypeProcess:2,$$$eHostTypeActor:2,$$$eHostTypeOperation:3,:4),tConfigItemName) = $G(pDeployDetails("Items",tItemName,"PoolSize"))
				}
			}
			Set tItemName = $O(pDeployDetails("Items",tItemName))
		}
		/* Disable those mentioned except if BP with pool size 0. */
		For tHostType = 4,3,2 {
			Set tConfigItemName = $O(tOrderedByType(tHostType,""))
			While (tConfigItemName '= "") {
				/* if BP and Pool size 0 do not disable */
				If ((tHostType '= 2)||(tOrderedByType(tHostType,tConfigItemName)'=0)) {
					Set tSC = ..DisableOneItem(tConfigItemName,tHostType,.tIsStillEnabled,.pItemsDisabled) 
					If (tIsStillEnabled || $$$ISERR(tSC)) {
						Set pSingleFailure =  $$$Text("Failed to disable an item")
						Quit	
					}
				} Else {
					Do ##class(Ens.Director).ParseConfigItemName(tConfigItemName,.tProductionName,.tHostItemName,.tCommentOrClass)
					Set tInfo = $$$Text("Not disabling Business Process with pool size 0")_": "_tHostItemName
				}
				Set tConfigItemName = $O(tOrderedByType(tHostType,tConfigItemName))
			}
		}
		Quit:(pSingleFailure'="")
	} Catch ex {
		Set tSC = ex.AsStatus()
	} 
	If (($$$ISERR(tSC) || (pSingleFailure'="")) && pAutoRevert) {
		Set tSC1 = ..RevertDisableItemsBeforeDeployment(.pItemsDisabled, .pRequiresManualIntervention)
		Set:$$$ISERR(tSC1) tSC = $$$ADDSC(tSC,tSC1)
	}
		
	Quit tSC
}

ClassMethod DisableOneItem(pConfigItemName As %String, pConfigType As %Integer, Output pIsStillEnabled, ByRef pItemsDisabled As %String) As %Status
{
	Set pIsStillEnabled = 1,tSC = $$$OK
	Try {
		Do ##class(Ens.Director).ParseConfigItemName(pConfigItemName,.tProductionName,.tHostItemName,.tCommentOrClass)
		$$$OutputDeployLog($$$Text("Disabling existing item")_" "_tHostItemName)
		Set tSC = ##class(Ens.Director).EnableConfigItem(pConfigItemName,0,1)
		Set pIsStillEnabled = $G($$$ConfigIsEnabled(tHostItemName),0)
		If pIsStillEnabled {	
			Set tFail1 = $$$Text("Failed to disable existing item")
			Set tFail2 = $$$Text("Aborting Deployment")
			Set tFail3 = $$$Text("Setting item back to enabled.")
			Set tSC1 = ##class(Ens.Director).EnableConfigItem(pConfigItemName,1,1)
			Set:($$$ISERR(tSC1)) tSC = $$$ADDSC(tSC,tSC1)
			$$$OutputDeployLog(tFail1_" "_tHostItemName_" "_tFail2_". "_tFail3)
		} Else {
			$$$OutputDeployLog($$$Text("Disabled existing item")_" "_tHostItemName)
			Set pItemsDisabled($CASE(pConfigType,$$$eHostTypeService:1,$$$eHostTypeProcess:2,$$$eHostTypeActor:2,$$$eHostTypeOperation:3,:4),pConfigItemName)="Settings:"_tHostItemName_".PTD"
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
		}
	Quit tSC
}

/// Re-enable items that had been disabled - alphabetical order
ClassMethod RevertDisableItemsBeforeDeployment(ByRef pItemsDisabled As %String, Output pRequiresManualIntervention As %String = "") As %Status
{
	Set tSC = $$$OK 
	Try {
		$$$OutputDeployLog($$$Text("Reverting initial disabling of items"))
		For tOrder = 4,3,2,1 {
			Set tConfigItemName = $O(pItemsDisabled(tOrder,""))
			Do ##class(Ens.Director).ParseConfigItemName(tConfigItemName,.tProductionName,.tHostItemName,.tCommentOrClass)
			While (tConfigItemName '= "") {
				$$$OutputDeployLog($$$Text("Renabling existing item due to failure to apply deployment file")_" ("_tHostItemName_")")
				Set tSC = ##class(Ens.Director).EnableConfigItem(tConfigItemName,1,1)
				Set:tSC tIsEnabled = $G($$$ConfigIsEnabled(tHostItemName),0)
				If ('tIsEnabled || $$$ISERR(tSC)) {
					Set tFail1 = $$$Text("Failed to re-enable existing item during abort")
					Set tFail2 = $$$Text("Requires manual intervention to re-enable")
					Set tFail3 = $$$Text("Setting item back to disabled.")
					Set tSC1 = ##class(Ens.Director).EnableConfigItem(tConfigItemName,0,1)
					Set:($$$ISERR(tSC1)) tSC = $$$ADDSC(tSC,tSC2)
					Set tInfo = tFail1_" "_tHostItemName_" "_tFail2_". "_tFail3
					$$$OutputDeployLog(tInfo)
					Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
					Quit
				}
				Set tConfigItemName = $O(pItemsDisabled(tOrder,tConfigItemName))
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod LoadAndCompileCode(ByRef pDeployDetails As %String, pFilename As %String, pRollbackFilename As %String, Output pErrors, Output pLoadedList, ByRef pStandardOBJLoadList As %String, Output pSingleFailure As %String, Output pRequiresManualIntervention As %String = "", pAutoRevert As %Boolean = 1)
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(Ens.Deployment.Utils).LoadAndCompileCode(pFilename,.pDeployDetails,.pErrors,.pLoadedList,.pStandardOBJLoadList,.pSingleFailure)
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	If ($$$ISERR(tSC) || (pSingleFailure'="")){
		If $$$ISERR(tSC) {$$$OutputDeployLog($$$StatusDisplayString(tSC))} Else {$$$OutputDeployLog(pSingleFailure)}
		If pAutoRevert{
			Set tSC1 = ..RevertLoadAndCompileCode(.pDeployDetails, pRollbackFilename, .pStandardOBJLoadList, .pRequiresManualIntervention)
			Set:('tSC1) tSC = $$$ADDSC(tSC,tSC1)
		}
	}				
	Quit tSC
}

ClassMethod RevertLoadAndCompileCode(ByRef pDeployDetails As %String, pRollbackFilename As %String, ByRef pStandardOBJLoadList As %String, Output pRequiresManualIntervention As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		/* Look for items that existed before and they ought to be in the rollback file. Others need to be deleted */
		$$$OutputDeployLog($$$Text("Reverting loading and compiling of code"))
		Set tItemName=$O(pStandardOBJLoadList(""))
		While tItemName '= "" {
			Set tLastDot = $LENGTH(tItemName)+2-$FIND($REVERSE(tItemName),".")
			Set tItemNameRootAndDot = $E(tItemName,1,tLastDot)
			Set tItemExt = $E(tItemName,tLastDot+1,*)
			Set tItemNameEXT = tItemNameRootAndDot_$ZCVT(tItemExt,"U")

			If ($G(pDeployDetails("Items",tItemNameEXT,"ExistDate")) '= -1) {
				Set tStandardOBJLoadListFromRollback(tItemName) = ""
			} Else {
				Set:'$G(pDeployDetails("Items",tItemNameEXT,"ItemIsSettings")) tStandardOBJToBeDelete(tItemNameEXT) = ""
			}
			Set tItemName=$O(pStandardOBJLoadList(tItemName))
		}
		If $D(tStandardOBJLoadListFromRollback) {
			$$$OutputDeployLog($$$Text("Reloading code from rollback file that was backed up")_" "_pRollbackFilename)
			Set tSC = ##class(Ens.Deployment.Utils).LoadAndCompileCode(pRollbackFilename,.pDeployDetails,.tRollbackLoadErrors,.tRollbackLoadedList,.tStandardOBJLoadListFromRollback,.pRequiresManualIntervention)
			Quit:$$$ISERR(tSC)
			If (pRequiresManualIntervention'="") {
				Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_pRequiresManualIntervention
				Set tInfo = pRequiresManualIntervention
			} Else {
				Set tInfo = $$$Text("Successfully imported from rollback")
			}
			$$$OutputDeployLog(tInfo)	
			Quit:(pRequiresManualIntervention'="")
		}
		If $D(tStandardOBJToBeDelete) {
			$$$OutputDeployLog($$$Text("Deleting code that was loaded during failed deployment"))
			Set tSC = ..DeleteObjects(.pDeployDetails,.tStandardOBJToBeDelete,"",.tSingleFailure,.pRequiresManualIntervention,0)
		}
	} Catch ex {
			Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

ClassMethod RemoveItemsFromProduction(pTargetProduction As %String, pHostItemsToRemove As %String, Output pHostItemRemovedStream As %String, pRollbackFilename As %String, Output pSingleFailure As %String, Output pRequiresManualIntervention As %String = "", pAutoRevert As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Quit:'$D(pHostItemsToRemove) tSC
	Try {
		Kill %objlasterror
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pTargetProduction,,.tSC)
		If '$IsObject(tProduction) {
			Set tInfo = $$$Text("Failed to open production")_" "_pTargetProduction_" : "_$$$StatusDisplayString(tSC)
			$$$OutputDeployLog(tInfo)
			Set pSingleFailure = tInfo
			Quit 
		}	
		Set tConfigItemName = $O(pHostItemsToRemove(""))
		While (tConfigItemName '= "") {
			Set tConfigItem=tProduction.FindItemByConfigName(tConfigItemName,.tSC)
			If $IsObject(tConfigItem) && (tConfigItem.Production = tProduction) {
				$$$OutputDeployLog($$$Text("Removing existing item as requested by deployment file")_" "_tConfigItemName)
				/* we remove but the queue entries remain. Need temp save of the stream for rollback*/
				Set tItemStr = ##class(%Stream.GlobalCharacter).%New()
				Set tSC = tConfigItem.XMLExportToStream(tItemStr)
				Set pHostItemRemovedStream(tConfigItemName) = tItemStr
				Do tProduction.RemoveItem(tConfigItem)
				Set tSC = tProduction.%Save()
				If $$$ISERR(tSC) {
					Set tInfo = $$$Text("Failed to save production after removing item as requested by deployment file")_" "_tConfigItemName
					$$$OutputDeployLog(tInfo)
					Set pSingleFailure = tInfo
					Set tProductionSaveFailure = 1
					Quit
				}
				Set tHostItemsRemoved(tConfigItemName) = ""
			}
			Set tConfigItemName = $O(pHostItemsToRemove(tConfigItemName))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set tProduction = ""
	
	If (((pSingleFailure'="")||$$$ISERR(tSC)) && $IsObject(tProduction) && pAutoRevert ) {
		Set tSC1 = ..RevertRemoveItemsFromProduction(.pHostItemRemovedStream, pRollbackFilename, pTargetProduction,.pRequiresManualIntervention)		
		Set:('tSC1) tSC = $$$ADDSC(tSC,tSC1)
	}	
	Quit tSC
}

ClassMethod RevertRemoveItemsFromProduction(ByRef pHostItemRemovedStream, pRollbackFilename As %String, pTargetProduction As %String, Output pRequiresManualIntervention As %String = "") As %Status
{
	Set tSC = $$$OK
	Quit:'$D(pHostItemRemovedStream) /* ConfigItemName */
	$$$OutputDeployLog($$$Text("Reverting removal of host items from the production"))
	Set tProduction = ##class(Ens.Config.Production).%OpenId(pTargetProduction,,.tSC)
	If '$IsObject(tProduction) {
		Set tErrorText = $$$StatusDisplayString(tSC)
		Set tInfo = $$$Text("Failed to open production to revert item removal")_" "_pTargetProduction_" "_tErrorText
		$$$OutputDeployLog(tInfo)
		Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
		Quit tSC
	}	
	Try {
		Set tConfigItemName = $O(pHostItemRemovedStream(""))
			While (tConfigItemName '= "") {
				/* item already deleted so can't open - use saved stream.*/
				/* check size of stream - if 0 then go to disk to get from rollback file */		
				Try { 
					Set tSize = pHostItemRemovedStream(tConfigItemName).Size
				} Catch exSize {
					Set tSize = 0
				}	
				Set tReader = ##class(%XML.Reader).%New()
				If tSize = 0 { /* We need to get get the XML from the rollback line */
					Set tItemStr = ##class(%Stream.GlobalCharacter).%New()
					Set tPTDName = "Settings:"_tConfigItemName
					If '$D(tRollbackDeploymentVDOC) Set tSC = ..GeneratePackageXMLVDOC(pRollbackFilename,.tRollbackDeploymentVDOC) 										
					If $$$ISERR(tSC) {
						Set tInfo = $$$Text("Failed to convert rollback file to XML VDoc")_" "_pRollbackFilename
						$$$OutputDeployLog(tInfo)
						Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
						Quit
					}
					Kill tPTDVDOC
					Set tSC = ..GeneratePTDXMLVDOC(pRollbackFilename,tRollbackDeploymentVDOC,tPTDName,.tPTDVDOC)
					If $$$ISERR(tSC) {
						Set tInfo = $$$Text("Failed to access Settings for")_" "_tPTDName_" "_$$$Text("from")_" "_pRollbackFilename
						$$$OutputDeployLog(tInfo)
						Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
						Quit
					}
					Set tSC = tReader.OpenString(tPTDVDOC.GetValueAt("/"))
					If $$$ISERR(tSC) {
						Set tInfo = $$$Text("Failed to access XML for string")_" "_tPTDName_" "_$$$Text("from")_" "_pRollbackFilename
						$$$OutputDeployLog(tInfo)
						Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
						Quit
					}
				} Else {
					Set tItemStr = pHostItemRemovedStream(tConfigItemName)
					Set tSC = tReader.OpenStream(tItemStr) quit:'(tSC)
					If $$$ISERR(tSC) {
						Set tInfo = $$$Text("Failed to access XML for stream")_" "_tPTDName_" "_$$$Text("from")_" "_pRollbackFilename
						$$$OutputDeployLog(tInfo)
						Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
						Quit
					}
				}
				Do tReader.Correlate("Item","Ens.Config.Item")
				Set tLoaded = tReader.Next(.tConfigItem,.tSC)
				Quit:('(tSC)||(tLoaded = 0))		
				If $IsObject(tConfigItem)  {
					$$$OutputDeployLog($$$Text("Re-Inserting removed item")_" "_tConfigItemName)
					Set tSC = tProduction.Items.Insert(tConfigItem)
					Set tSC = tProduction.%Save()
					If $$$ISERR(tSC) {
						Set tInfo = $$$Text("Failed to save production after attempting re-inserting item")_" "_tConfigItemName
						$$$OutputDeployLog(tInfo)
						Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
						Quit
					}
				}
				Set tConfigItemName = $O(pHostItemRemovedStream(tConfigItemName))
			}
			If ($$$ISERR(tSC) || (tLoaded = 0)) {
				Set tInfo = $$$Text("Failure re-inserting removed items")_":"_$$$StatusDisplayString(tSC)
				$$$OutputDeployLog(tInfo)
				Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
			}
		} Catch ex {
			Set tSC = ex.AsStatus()
			Set tInfo = $$$Text("Failure re-inserting removed items")_":"_$$$StatusDisplayString(tSC)
			$$$OutputDeployLog(tInfo)
			Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
		}
	Quit tSC
}

/// Make changes to host items.
ClassMethod MakeHostItemChanges(Output pItemsInsertedId As %String, ByRef pDeployDetails As %String, pTargetProduction As %String, pFilename As %String, pRollbackFilename As %String, Output pSingleFailure As %String, Output pRequiresManualIntervention As %String = "", pAutoRevert As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Set tProduction = ""
	Try {
		Set tItemName = $O(pDeployDetails("Items","")),tProduction = ""
		While tItemName '= "" {
			If $G(pDeployDetails("Items",tItemName,"ItemIsSettings")) {
				Set tProductionId = $G(pDeployDetails("Items",tItemName,"ItemProductionTarget"),pTargetProduction) 
				Set:'$IsObject(tProduction) tProduction = ##class(Ens.Config.Production).%OpenId(tProductionId,,.tSC) /* only open the production once */
				If '$IsObject(tProduction) {
					Set tErrorText = $$$StatusDisplayString(tSC)
					Set tInfo = $$$Text("Failed to open production")_" "_tProductionId_" "_tErrorText
					$$$OutputDeployLog(tInfo)
					Set pSingleFailure = tInfo
					Quit
				}	
				If $G(pDeployDetails("Items",tItemName,"ItemAlreadyInProduction")) {
					If $D(pDeployDetails("Items",tItemName,"CompareItemSettingChanges","ChangeProperty","Enabled","Deploy")) {
						/*   
							Logic: we are dealing with existing items and we are here since the Enabled value has changed from what it was
								a) if the item had been Enabled then we have already disabled at start of the deployment. unless it was a BP in which case we didn't.
								By changing the value of EnabledStatusAtDeploy we hoped to fool the renabledisabled items.. since by reversing to 0 it won't get re-enabled. but bps will fall through the crack
								b) if the item were disabled at start then the idea is to pick up the EnabledStatusAtDeploy flag but code path has changed.
								
								
						*/
						Set pDeployDetails("Items",tItemName,"EnabledStatusAtDeploy") = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges","ChangeProperty","Enabled","Deploy"))
					}
					Set tConfigItemName = $G(pDeployDetails("Items",tItemName,"ConfigItemName")) 
					Set tConfigItem=tProduction.FindItemByConfigName(tConfigItemName,.tSC)
					If $IsObject(tConfigItem) && (tConfigItem.Production = tProduction) {
						/* 	
							We already compared when generating pDeployDetails
							Go through pItem1SettingChanges
							The output is pItem1SettingChanges is an array:
								pItem1.Name,ChangeProperty,Name,Deploy & Current = Value
								pItem1.Name,[ChangeSetting,AddSetting,RemoveSetting],Name,Target,Deploy & Current [If ChangeSetting] = Value
						*/
						Set tChangeAction = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",""))
						While (tChangeAction '= "") {
							Set tChangePropOrSettingName = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,""))
							While (tChangePropOrSettingName '= "") {
								If (tChangeAction = "ChangeProperty") {
									Set tDeployValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,"Deploy"))
									Set tCurrentValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,"Current"))
									If tChangePropOrSettingName = "Enabled" {
										Set $PROPERTY(tConfigItem,tChangePropOrSettingName) = 0 /* Will put back to enabled if needed later */
										$$$OutputDeployLog($$$Text("Setting enabled for item")_" "_tConfigItemName_" "_$$$Text("to")_" 0 "_$S(pDeployDetails("Items",tItemName,"EnabledStatusAtDeploy"):$$$Text("But will change back to 1 later"),1:""))
									} Else {
										Set $PROPERTY(tConfigItem,tChangePropOrSettingName) = tDeployValue
										$$$OutputDeployLog($$$Text("Changing property for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_" "_$$$Text("from")_" "_tCurrentValue_" "	_$$$Text("to")_" "_tDeployValue)
									}
								} Else {/*Setting*/
									/* walk over target subscript */
									Set tSettingTarget = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,""))
									While (tSettingTarget '= "") {
										/* ChangeSetting,AddSetting,RemoveSetting*/
										If (tChangeAction = "RemoveSetting") {
											$$$OutputDeployLog($$$Text("Removing setting for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_"("_tSettingTarget_")")
											Set tSC = ##class(EnsPortal.ProductionConfig).RemoveSettingByName(tConfigItem,tChangePropOrSettingName,tSettingTarget)
											If $$$ISERR(tSC) {
												Set tInfo = $$$Text("Failed to remove setting")_" "_tChangePropOrSettingName_" "_$$$Text("from")_" "_tConfigItemName
												$$$OutputDeployLog(tInfo)
												Set pSingleFailure = tInfo
												Quit	
											}
										} ElseIf (tChangeAction = "AddSetting"){
											Set tSetting = ##class(Ens.Config.Setting).%New()
											Set tSetting.Name = tChangePropOrSettingName
											Set tSetting.Target = tSettingTarget
											Set tSetting.Value = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget))
											Do tConfigItem.Settings.Insert(tSetting)
											$$$OutputDeployLog($$$Text("Adding setting for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_"("_tSettingTarget_") "_$$$Text("with value of")_" "_tSetting.Value)
										} ElseIf (tChangeAction = "ChangeSetting") {
											Set tSetting = tConfigItem.FindSettingByName(tChangePropOrSettingName, tSettingTarget)
											If $IsObject(tSetting) {
												Set tDeployValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget,"Deploy"))
												Set tCurrentValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget,"Current"))
												Set tSetting.Value = tDeployValue
												$$$OutputDeployLog($$$Text("Changing setting for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_"("_tSettingTarget_") "_$$$Text("from")_" "_tCurrentValue_" "_$$$Text("to")_" "_tDeployValue)
											} Else {
												Set tInfo = $$$Text("Failed to modifiy setting")_" "_tChangePropOrSettingName_" "_$$$Text("in")_" "_tConfigItemName
												$$$OutputDeployLog(tInfo)
												Set pSingleFailure = tInfo
												Quit	
											}
										}
										Set tSettingTarget = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget))
									} 
								}				
								Set tChangePropOrSettingName = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName))
							}
							Set tChangeAction = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction))
						}
						Set tSC = tProduction.%Save()
						If $$$ISERR(tSC) {
							Set tInfo = $$$Text("Failed to save production after changing item")_" "_tConfigItemName
							$$$OutputDeployLog(tInfo)
							Set pSingleFailure = tInfo
							Quit
						}
					} Else {
						Set tInfo = $$$Text("Failed to open existing production item")_" "_tConfigItemName
						$$$OutputDeployLog(tInfo)
						Set pSingleFailure = tInfo
						Quit	
					}
				} Else { 
					Set tPTDName = $P(tItemName,".PTD")
					$$$OutputDeployLog($$$Text("Loading item settings")_" "_tPTDName)
					Set tSC = ##class(Ens.Util.ProjectTextDocument).GetStream(.tStream,tPTDName)
					Set tReader = ##class(%XML.Reader).%New()
					Set tSC=tReader.OpenStream(tStream) quit:'(tSC)
					Do tReader.Correlate("Item","Ens.Config.Item")
					Set tLoaded = tReader.Next(.tItem,.tSC) ;Expect 1 item
					If (tSC && tLoaded) {	
						Set pDeployDetails("Items",tItemName,"EnabledStatusAtDeploy")=tItem.Enabled
						Set tItem.Enabled = 0
					} Else {
						Set tInfo = $$$Text("Failed to correlate item")_" "_tPTDName
						$$$OutputDeployLog(tInfo)
						Set pSingleFailure = tInfo
						Quit
					}
					Set tInfo = $$$Text("Inserting new item")_" "_tItemName
					$$$OutputDeployLog(tInfo)
					Set tSC = tProduction.Items.Insert(tItem)
					Quit:$$$ISERR(tSC)
					Set tSC = tProduction.%Save()
					If $$$ISERR(tSC) {
						Set tInfo = $$$Text("Failed to save production after inserting item")_" "_tItemName
						$$$OutputDeployLog(tInfo)
						Set pSingleFailure = tInfo
						Quit
					}
					Set:tSC pItemsInsertedId(tItem.%Id())=""
				}
				Quit:((pSingleFailure'="")||$$$ISERR(tSC))
				
				If $$$ISERR(tSC) {
					Set tInfo = $$$Text("Failed to save production after modifying item")_" "_tConfigItemName
					$$$OutputDeployLog(tInfo)
					Set pSingleFailure = tInfo
					Quit
				}
			}
			Set tItemName = $O(pDeployDetails("Items",tItemName))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	If (((pSingleFailure'="")||$$$ISERR(tSC)) && pAutoRevert) {
		Set tSC1 = ..RevertMakeHostItemChanges(.pItemsInsertedId,.pDeployDetails, pRollbackFilename, pTargetProduction, .pRequiresManualIntervention)
		}
	Quit tSC
}

/// Revert changes made to host items
ClassMethod RevertMakeHostItemChanges(ByRef pItemsInsertedId, ByRef pDeployDetails As %String, pRollbackFilename As %String, pTargetProduction As %String, Output pRequiresManualIntervention As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		$$$OutputDeployLog($$$Text("Reverting host item changes"))
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pTargetProduction,,.tSC) 
		If '$IsObject(tProduction) {
			Set tErrorText = $$$StatusDisplayString(tSC)
			$$$OutputDeployLog($$$Text("Failed to open production")_" "_pTargetProduction_" : "_tErrorText)
			Quit
		}	
		Set tItemIdAddedId = $O(pItemsInsertedId(""))
		While tItemIdAddedId '= "" {
			Set tItem = ##class(Ens.Config.Item).%OpenId(tItemIdAddedId,,.tSC)
			If $$$ISERR(tSC) {
				Set tInfo = $$$Text("Failed to open item to remove. Item id:")_" "_tItemIdAddedId
				$$$OutputDeployLog(tInfo)
				Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
				Quit
			}
			Do tProduction.RemoveItem(tItem)
			Set tSC = tProduction.%Save()
			If $$$ISERR(tSC) {
				Set tInfo = $$$Text("Failed to save production after removing item while reverting changes. Item id:")_" "_tItemIdAddedId
				$$$OutputDeployLog(tInfo)
				Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
				Quit
			}
			Set tItemIdAddedId = $O(pItemsInsertedId(tItemIdAddedId))
		}
	
		Set tItemName = $O(pDeployDetails("Items",""))
		While tItemName '= "" {
			If ($G(pDeployDetails("Items",tItemName,"ItemIsSettings")) && $G(pDeployDetails("Items",tItemName,"ItemAlreadyInProduction"))) {
				/* 	Existing items already disabled. Update Enabled status at deployment in case changed */
				If $D(pDeployDetails("Items",tItemName,"CompareItemSettingChanges","ChangeProperty","Enabled","Current")) {
					Set pDeployDetails("Items",tItemName,"EnabledStatusAtDeploy") = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges","ChangeProperty","Enabled","Current"))
				}
				Set tConfigItemName = $G(pDeployDetails("Items",tItemName,"ConfigItemName")) 
				Set tConfigItem=tProduction.FindItemByConfigName(tConfigItemName,.tSC)
				If $IsObject(tConfigItem) && (tConfigItem.Production = tProduction) {
					$$$OutputDeployLog($$$Text("Reversing existing item")_" "_tConfigItemName)
					Set tChangeAction = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",""))
					While (tChangeAction '= "") {
						Set tChangePropOrSettingName = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,""))
						While (tChangePropOrSettingName '= "") {
							If (tChangeAction = "ChangeProperty") {
								Set tDeployValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,"Deploy"))
								Set tCurrentValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,"Current"))
								If tChangePropOrSettingName = "Enabled" {
									Set $PROPERTY(tConfigItem,tChangePropOrSettingName) = 0 /* Will put back to enabled if needed later */
									$$$OutputDeployLog($$$Text("Setting enabled for item")_" "_tConfigItemName_" "_$$$Text("to")_" 0 "_$S(pDeployDetails("Items",tItemName,"EnabledStatusAtDeploy"):$$$Text("But will change back to 1 later"),1:""))
								} Else {
									Set $PROPERTY(tConfigItem,tChangePropOrSettingName) = tCurrentValue
									$$$OutputDeployLog($$$Text("Changing property back for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_" "_$$$Text("from")_" "_tDeployValue_" "	_$$$Text("to")_" "_tCurrentValue)
								}
							} Else {/*Setting*/
								/* walk over target subscript */
								Set tSettingTarget = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,""))
								While (tSettingTarget '= "") {
									/* ChangeSetting,AddSetting,RemoveSetting, value of removed is stored so we can put back */
									If (tChangeAction = "RemoveSetting") {
										Set tSetting = ##class(Ens.Config.Setting).%New()
										Set tSetting.Name = tChangePropOrSettingName
										Set tSetting.Target = tSettingTarget
										Set tSetting.Value = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget))
										Do tConfigItem.Settings.Insert(tSetting)
										$$$OutputDeployLog($$$Text("Adding back setting for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_"("_tSettingTarget_") "_$$$Text("with value of")_" "_tSetting.Value)
									} ElseIf (tChangeAction = "AddSetting"){
										$$$OutputDeployLog($$$Text("Removing added setting for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_"("_tSettingTarget_")")
										Set tSC = ##class(EnsPortal.ProductionConfig).RemoveSettingByName(tConfigItem,tChangePropOrSettingName,tSettingTarget)
										If $$$ISERR(tSC) {
											Set tInfo = $$$Text("Failed to remove setting")_" "_tChangePropOrSettingName_" "_$$$Text("from")_" "_tConfigItemName
											$$$OutputDeployLog(tInfo)
											Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
											Quit	
										}
									} ElseIf (tChangeAction = "ChangeSetting") {
										Set tSetting = tConfigItem.FindSettingByName(tChangePropOrSettingName, tSettingTarget)
										If $IsObject(tSetting) {
											Set tDeployValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget,"Deploy"))
											Set tCurrentValue = $G(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget,"Current"))
											Set tSetting.Value = tCurrentValue
											$$$OutputDeployLog($$$Text("Changing setting back for item")_" "_tConfigItemName_":"_tChangePropOrSettingName_"("_tSettingTarget_") "_$$$Text("from")_" "_tDeployValue_" "_$$$Text("to")_" "_tCurrentValue)
										} Else {
											Set tInfo = $$$Text("Failed to modifiy setting")_" "_tChangePropOrSettingName_" "_$$$Text("in")_" "_tConfigItemName
											$$$OutputDeployLog(tInfo)
											Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
											Quit	
										}
									}
									Set tSettingTarget = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName,tSettingTarget))
								} 
							}				
							Set tChangePropOrSettingName = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction,tChangePropOrSettingName))
						}
						Set tChangeAction = $O(pDeployDetails("Items",tItemName,"CompareItemSettingChanges",tChangeAction))
						Set tSC = tProduction.%Save()
						If $$$ISERR(tSC) {
							Set tInfo = $$$Text("Failed to save production after changing item while reverting changes for")_" "_tConfigItemName
							$$$OutputDeployLog(tInfo)
							Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
							Quit
						}
					}
				} Else {
					Set tInfo = $$$Text("Failed to open existing production item")_" "_tConfigItemName
					$$$OutputDeployLog(tInfo)
					Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
					Quit	
				}
			} 
			Quit:((pRequiresManualIntervention'="")||$$$ISERR(tSC))
			
			If $$$ISERR(tSC) {
				Set tInfo = $$$Text("Failed to save production after modifying item")_" "_tConfigItemName
				$$$OutputDeployLog(tInfo)
				Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_tInfo
				Quit
			}
			Set tItemName = $O(pDeployDetails("Items",tItemName))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set tInfo = $$$Text("Failure revert host item changes")_":"_$$$StatusDisplayString(tSC)		
		$$$OutputDeployLog(tInfo)
	}
	Set:($$$ISERR(tSC) && (pRequiresManualIntervention = "")) pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_$G(tInfo)
	Quit tSC
}

ClassMethod DeleteObjects(ByRef pDeployDetails, ByRef pObjectsToDelete As %String, pRollbackFilename As %String, Output pSingleFailure As %String = "", Output pRequiresManualIntervention As %String = "", pAutoRevert As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Quit:'$D(pObjectsToDelete) tSC
	Try {
		Set tItemName = $O(pObjectsToDelete(""))
		While (tItemName '= "") {
			Set tSC = ##class(%RoutineMgr).Delete(tItemName)
			If $$$ISERR(tSC) {
				Set tInfo = $$$Text("Failed to delete")_" "_tItemName
				$$$OutputDeployLog(tInfo)
				Set pSingleFailure = tInfo
			} Else {
				$$$OutputDeployLog($$$Text("Deleted")_" "_tItemName)
			}
			Set tItemName = $O(pObjectsToDelete(tItemName))
		}
	} Catch ex {
			Set tSC = ex.AsStatus()
	}
	If (((pSingleFailure'="")||$$$ISERR(tSC)) && pAutoRevert) {
		Set tSC1 = ..RevertDeleteObjects(.pDeployDetails,.pObjectsToDelete,pRollbackFilename,.pRequiresManualIntervention)
		Set tSC = $$$ADDSC(tSC,tSC1)
	}
	Quit tSC
}

ClassMethod RevertDeleteObjects(ByRef pDeployDetails As %String, ByRef pObjectsToDelete As %String, pRollbackFilename As %String, Output pRequiresManualIntervention As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		$$$OutputDeployLog($$$Text("Reverting deletion of code"))
		$$$OutputDeployLog($$$Text("Reloading code from rollback file")_" "_pRollbackFilename)
		Set tSC = ##class(Ens.Deployment.Utils).LoadAndCompileCode(pRollbackFilename,.pDeployDetails,.tRollbackLoadErrors,.tRollbackLoadedList,.pObjectsToDelete,.pRequiresManualIntervention)
		Quit:$$$ISERR(tSC)
		If (pRequiresManualIntervention'="") {
			Set pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_pRequiresManualIntervention
			Set tInfo = pRequiresManualIntervention
		} Else {
			Set tInfo = $$$Text("Successfully imported from rollback")
		}
		$$$OutputDeployLog(tInfo)	
	} Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Set:($$$ISERR(tSC) && (pRequiresManualIntervention = "")) pRequiresManualIntervention = $$$Text("Manual intervention required")_": "_$$$StatusDisplayString(tSC)
	Quit tSC
}

/// Make the changes to the target production settings
ClassMethod ChangeProductionSettings(pTargetProductionName As %String, ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK
	Try {	
		Set tItemName = $G(pDeployDetails("ProductionSettings"))
		Quit:(tItemName = "")		
		$$$OutputDeployLog($$$Text("Applying production settings from deployment file"))
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pTargetProductionName,,.tSC)
		If $$$ISERR(tSC) || '$IsObject(tProduction) {
			Set tInfo = $$$Text("Failed to open production")_" "_pTargetProductionName_" : "_$$$StatusDisplayString(tSC)
			$$$OutputDeployLog(tInfo)
			Set tSC=$$$ERROR($$$EnsErrGeneral,tInfo)
			Quit
		}
		Set tProduction.Description = pDeployDetails("Items",tItemName,"ProdSettings","Description")
		Set tProduction.ActorPoolSize = pDeployDetails("Items",tItemName,"ProdSettings","ActorPoolSize")
		Set tProduction.TestingEnabled = pDeployDetails("Items",tItemName,"ProdSettings","TestingEnabled")
		Set tProduction.LogGeneralTraceEvents = pDeployDetails("Items",tItemName,"ProdSettings","LogGeneralTraceEvents")
		Merge tSettingsArray = pDeployDetails("Items",tItemName,"ProdSettings","Settings")
		Set tSC = tProduction.UpdateSettings(.tSettingsArray)
		Quit:$$$ISERR(tSC)
		Set tSC = tProduction.%Save()
		For tC = 1:1:$G(pDeployDetails("Items",tItemName,"ReportDifferences")) {$$$OutputDeployLog($G(pDeployDetails("Items",tItemName,"ReportDifferences",tC)))}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tInfo = $$$Text("Failed to update production settings")_" "_$$$StatusDisplayString(tSC)
		$$$OutputDeployLog(tInfo)
	}				
	Quit tSC
}

/// This method enables all items that ought to be enabled. 
/// This covers those disabled at the start of deployment, those items added by the deployment 
/// and those items whose Enabled flag was turned on by the deployment.
ClassMethod EnableDisabledItemsThatAreFlaggedEnabled(ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		For tHostType = 4,3,2,1,-1 {
			Set tItemName = $O(pDeployDetails("ItemsByBusinessType",tHostType,""))
			While tItemName '= "" {
				If (($G(pDeployDetails("Items",tItemName,"EnabledStatusAtDeploy")) = 1)&&(+$G(pDeployDetails("Items",tItemName,"PoolSize"))||(tHostType'=2))) {
					Set tProductionId = $G(pDeployDetails("Items",tItemName,"ItemProductionTarget")) 
					Set tConfigItemName = $G(pDeployDetails("Items",tItemName,"ConfigItemName")) 
					Set:((tProductionId'="")&&($L(tConfigItemName,"||")=1)) tConfigItemName = tProductionId_"||"_tConfigItemName /* prepend productionid_"||"_tConfigItemName */
					Do ##class(Ens.Director).ParseConfigItemName(tConfigItemName,.tProductionName,.tHostItemName,.tCommentOrClass)
					$$$OutputDeployLog($$$Text("Enabling item")_" "_tHostItemName)
					Set tSC = ##class(Ens.Director).EnableConfigItem(tConfigItemName,1,0)
				}
				Set tItemName = $O(pDeployDetails("ItemsByBusinessType",tHostType,tItemName))
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod SaveToClass(pTargetProduction As %String, ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK, tErrorText = ""
	Try {
		If '##class(Ens.Config.Production).%ExistsId(pTargetProduction) {
			$$$OutputDeployLog($$$Text("Production does not exist anymore and hence cannot call SaveToClass"))
			Quit
		}
		Set:'$$$ISERR(tSC) tSC = ##class(Ens.Deployment.Utils).SourceControlProductionSave(pTargetProduction,"checkout",.pDeployDetails)
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pTargetProduction,,.tSC)
		If '$IsObject(tProduction) {
			Set tErrorText = $$$StatusDisplayString(tSC)
			Set tInfo = $$$Text("Failed to open production")_" "_pTargetProduction_" "_tErrorText
			$$$OutputDeployLog(tInfo)
			Set:tSC tSC = $$$ERROR($$$EnsErrGeneral, tInfo) 
			Quit
		}
		$$$OutputDeployLog($$$Text("Saving host item changes to production class definition.")_$$$Text("Production Configuration screens open in the portal will need refreshing."))
		Set tSC = tProduction.SaveToClass()  
		Set:'$$$ISERR(tSC) tSC = ##class(Ens.Deployment.Utils).SourceControlProductionSave(pTargetProduction,"compiled",.pDeployDetails)
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod UpdateProduction() As %Status
{
	Set tSC = $$$OK
	Try {
		If ##class(Ens.Director).ProductionNeedsUpdate(.tReasons) {
			$$$OutputDeployLog($$$Text("Updating Production")_": "_tReasons)
			Set tSC=##class(Ens.Director).UpdateProduction()
		} Else {
			$$$OutputDeployLog($$$Text("Production does not need updating"))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	If ##class(Ens.Director).ProductionNeedsUpdate(.tReasons) $$$OutputDeployLog($$$Text("Production still needs updating")_": "_tReasons)
	Quit tSC
}

/// Remove temporary Project Text Documents created during deployment
ClassMethod PTDCleanup(ByRef pPTDToDelete As %String) As %Status
{
	Set tSC = $$$OK
	Quit:'$D(pPTDToDelete) tSC
	Try {
		Set tPTDToDelete = $O(pPTDToDelete(""))
		While tPTDToDelete '= "" {
			Set tSC = ##class(%RoutineMgr).Delete(tPTDToDelete)
			Set tPTDToDelete = $O(pPTDToDelete(tPTDToDelete))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Make rollback instructions of the items that will be modified by the deployment file.
/// This rollback file can be applied as a deployment file.
ClassMethod MakePreDeploymentRollback(pDeploymentFile As %String, pRollbackFilename As %String, ByRef pDeployDetails As %String, pProjectName As %String = "", pDescription As %String = "") As %Status
{
	Set tSC = $$$OK
	Set tItemName = $O(pDeployDetails("Items","")),tHaveItemsToRollback = 0
	While tItemName '= "" {
		Set tInfo = ""
		Set tItemType = $G(pDeployDetails("Items",tItemName,"Type"))
		Set tItemExistDate = $G(pDeployDetails("Items",tItemName,"ExistDate"),-1) ;-1 makes it so does not exist 
		Set tItemIsProductionClass = $G(pDeployDetails("Items",tItemName,"ItemIsProductionClass")) 
		Set tItemIsSettings = $G(pDeployDetails("Items",tItemName,"ItemIsSettings")) 
		Set tProductionId = $G(pDeployDetails("Items",tItemName,"ItemProductionTarget")) 
		Set tConfigItemName = $G(pDeployDetails("Items",tItemName,"ConfigItemName")) 
		Set tItemAlreadyInProduction = $G(pDeployDetails("Items",tItemName,"ItemAlreadyInProduction")) 
		If tItemIsSettings {
			If (tItemAlreadyInProduction && (tProductionId '="")) {
				Set tConfigItem = ##class(Ens.Config.Production).OpenItemByConfigName(tProductionId_"||"_tConfigItemName,.tSC)
				If $$$ISERR(tSC) || '$IsObject(tConfigItem) {
					Set tInfo = $$$Text("Failed to open config item with name")_" "_tConfigItemName_" "_$$$Text("in Production")_" "_tProductionId_" : "_$$$StatusDisplayString(tSC)
					$$$OutputDeployLog(tInfo)
					Set tSC = $$$ERROR($$$EnsErrGeneral, tInfo )
					Quit
				}
				Set tItemStr = ##class(%Stream.GlobalCharacter).%New()
				Set tSC=tConfigItem.XMLExportToStream(tItemStr)  Quit:$$$ISERR(tSC)
				Do tItemStr.Rewind()
				Set tPTDName="Settings:"_tConfigItem.Name
				Do:##class(%RoutineMgr).Exists(tPTDName_".PTD") ##class(%RoutineMgr).Delete(tPTDName_".PTD")
				Do ##class(Ens.Util.ProjectTextDocument).Create(tItemStr,tPTDName,"Rollback Settings for "_tConfigItem.Name_" in Production "_tProductionId)	
				Set tFullList(tPTDName_".PTD")=""
				Set tPTDToDelete(tPTDName_".PTD")=""
				Set tConfigItem = ""
				Set tInfo = $$$Text("Will save settings for item")_" "_tConfigItemName
				$$$OutputDeployLog(tInfo)
				Set tHaveItemsToRollback = tHaveItemsToRollback + 1
			} Else {
				Set:(tProductionId '="") tItemsAdded(tItemName)=""
			}
		} ElseIf ($G(pDeployDetails("Items",tItemName,"ProdSettings"))=1){
			/* Need to make a PTD for the current production */
			/* Note if the source production name is different then the PTD we make will be different */
			Set tProduction = ##class(Ens.Config.Production).%OpenId(tProductionId,,.tSC)
			If $$$ISERR(tSC) || '$IsObject(tProduction) {
				Set tInfo = $$$Text("Failed to open production")_" "_tProductionId_" : "_$$$StatusDisplayString(tSC)
				$$$OutputDeployLog(tInfo)
				Set tSC=$$$ERROR($$$EnsErrGeneral,tInfo)
				Quit
			}
			Set tSC = ##class(Ens.Deployment.Utils).CreatePTDFromProduction(tProduction,.tPTDName)
			Quit:$$$ISERR(tSC)
			Set tFullList(tPTDName_".PTD")=""
			Set tPTDToDelete(tPTDName_".PTD")=""
			Set tProduction = ""	
		} Else {
			If tItemExistDate '= -1 {
				Set tFullList(tItemName) = "",tInfo = $$$Text("Will save item")_" "_tItemName
				$$$OutputDeployLog(tInfo)
				Set tHaveItemsToRollback = tHaveItemsToRollback + 1
			} Else {
				Set tItemsAdded(tItemName)=""
			}
			Set:(($E(tItemName,1,14) = "EnsExportNotes") || ($E(tItemName,1,15) = "EnsExportRemove")) tPTDToDelete(tItemName)=""			}			
			Set tItemName = $O(pDeployDetails("Items",tItemName))
		}
		Quit:($$$ISERR(tSC)) tSC
		
		Set tItemName = $O(pDeployDetails("Remove",""))
		While tItemName '= "" {
			If ("Settings:" = $E(tItemName,1,9)) {
				Set tConfigItemName = $P($P(tItemName,"Settings:",2),".PTD")
				Set tConfigItem = ##class(Ens.Config.Production).OpenItemByConfigName(tProductionId_"||"_tConfigItemName,.tSC)
				If $$$ISERR(tSC) || '$IsObject(tConfigItem) {
					Set tInfo = $$$Text("Failed to open config item with name")_" "_tConfigItemName_" "_$$$Text("in Production")_" "_tProductionId_" : "_$$$StatusDisplayString(tSC)
					$$$OutputDeployLog(tInfo)
					Set tSC=$$$ERROR($$$EnsErrGeneral,tInfo)
					Quit
				}
				Set tItemStr = ##class(%Stream.GlobalCharacter).%New()
				Set tSC=tConfigItem.XMLExportToStream(tItemStr)  Quit:$$$ISERR(tSC)
				Do tItemStr.Rewind()	
				Set tPTDName="Settings:"_tConfigItemName
				Do:##class(%RoutineMgr).Exists(tPTDName_".PTD") ##class(%RoutineMgr).Delete(tPTDName_".PTD")
				Do ##class(Ens.Util.ProjectTextDocument).Create(tItemStr,tPTDName,"Rollback Settings for "_tConfigItemName_" in Production "_tProductionId)	
				Set tFullList(tPTDName_".PTD")=""
				Set tPTDToDelete(tPTDName_".PTD")="" 
				Set tConfigItem = ""
				Set tInfo = $$$Text("Will save settings for item to be removed")_" "_tConfigItemName
				$$$OutputDeployLog(tInfo)
				Set tHaveItemsToRollback = tHaveItemsToRollback + 1
			} Else {
				Set tFullList(tItemName) = "" /* Export non settings */	
			}
			Set tItemName = $O(pDeployDetails("Remove",tItemName))
		}
		Quit:($$$ISERR(tSC)) tSC
		
		If 'tHaveItemsToRollback {Set tInfo = $$$Text("No existing items to rollback") $$$OutputDeployLog(tInfo)}
		
		If (pProjectName = "") {
				Set pProjectName="EnsExportRollback_"_$TR(##class(Ens.Util.Time).FormatDateTime("%Q%#z",,$$$timeUTC) , ".","_")
			} Else {
				Set:($E(pProjectName,1,15)'="EnsExportRollback") pProjectName="EnsExportRollback_"_pProjectName
		}
		Set:($L(pProjectName)>64) pProjectName = $E(pProjectName,1,64)
		
		/* Make Remove PTD for rollback */
		Set tSC =##class(Ens.Deployment.Utils).CreateExportRemovePTD(pProjectName,tProductionId,.tItemsAdded,.tPTDName,pRollbackFilename,pDeploymentFile)
		If (tPTDName '= "") {
			Set tFullList(tPTDName_".PTD")=""
			Set tPTDToDelete(tPTDName_".PTD")=""
		}
		
		/* Make notes PTD for rollback */
		Set tSC =##class(Ens.Deployment.Utils).CreateExportNotesPTD(pProjectName,tProductionId,$$$Text("Generated by rollback"),.tFullList,($G(tProductionClassIncluded)'=""),.tPTDName,pRollbackFilename,pDeploymentFile)
		Set tFullList(tPTDName_".PTD")=""
		Set tPTDToDelete(tPTDName_".PTD")=""
		
		Set tProject=##class(%Studio.Project).%New()
		If '$IsObject(tProject) quit $$$ERROR($$$EnsErrGeneral,"Failed to create project object.")
		Set:(pDescription = "") pDescription = "Studio Project generated for rollback prior to applying changes at "_##class(Ens.Util.Time).FormatDateTime("%K(UTC)%Q UTC",,$$$timeUTC)		 
		Set tProject.Name=pProjectName
		Set tProject.Description=pDescription
		Set tItemName = $O(tFullList("")) 
		While tItemName '= "" {
			Do tProject.AddItem(tItemName)
			Set tItemName = $O(tFullList(tItemName)) 
		}
		Set tSC = tProject.%Save()
		Set:tSC tFullList(tProject.Name_".prj")=""
		Set tSC=$system.OBJ.Export(.tFullList,pRollbackFilename,"-d")	
		Set tInfo = $$$Text("Exporting items to rollback file")_" "_pRollbackFilename
		$$$OutputDeployLog(tInfo)
		Do ##class(%Studio.Project).%DeleteId(pProjectName)	
		Set tSC = ..PTDCleanup(.tPTDToDelete)
		Quit:$$$ISERR(tSC) tSC
		If '##class(%File).Exists(pRollbackFilename) {
			Set tInfo = $$$Text("Failed to create")_" "_$$$Text("Rollback file.")_" "_$$$Text("Possible permissions or legal filename restriction.")
			$$$OutputDeployLog(tInfo)
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
		}
		Quit tSC
}

/// Obtain a deployment token for this namespace on this instance on this machine
ClassMethod GetDeploymentToken(ByRef pSourceInfo As %String, ByRef pTargetInfo As %String, Output pSC As %Status) As Ens.Deployment.Token
{
	Set pSC = $$$OK, tDeploymentToken = $$$NULLOREF
	Try {
		If ##class(Ens.Deployment.Token).%ExistsId("DeployToken") {
			Set tDeploymentToken = ##class(Ens.Deployment.Token).%OpenId("DeployToken",4,.pSC)
			If $$$ISERR(pSC) {
				If $$$StatusEquals(pSC,$$$LockFailedToAcquireExclusive) {
					Set tInfo = $$$Text("Deployment token for this namespace is in use.")
					$$$OutputDeployLog(tInfo)
					Set tInfoErr = $$$ERROR($$$EnsErrGeneral,tInfo)
					Set pSC = $$$ADDSC(pSC,tInfoErr)
				} 
				Quit
			} ElseIf tDeploymentToken.InProgress {
				Set tInfo = $$$Text("Deployment token for this namespace was marked as InProgress by job")_": "_tDeploymentToken.Job_". "
				Set tInfo = tInfo_$$$Text("But this job does not have the token open.")
				$$$OutputDeployLog(tInfo)
				Set tDeploymentToken = "" 
				Set pSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			}
		} Else {		
				Set tDeploymentToken=##class(Ens.Deployment.Token).%New()
				Set tDeploymentToken.TargetMachine = pTargetInfo("Machine")
				Set tDeploymentToken.TargetInstance = pTargetInfo("Instance")
				Set tDeploymentToken.TargetNamespace = pTargetInfo("Namespace")
				Set tDeploymentToken.Token = "DeployToken"
				Set pSC = tDeploymentToken.%Save()
				If $$$ISERR(pSC) {
					Set tInfo = $$$Text("Failed to save new Deployment token for this namespace.")
					$$$OutputDeployLog(tInfo)
					Set tInfoErr = $$$ERROR($$$EnsErrGeneral,tInfo)
					Set pSC = $$$ADDSC(pSC,tInfoErr)
				}
		} 
	} Catch ex {
		Set pSC = ex.AsStatus()	
	}
	If ((tDeploymentToken '= "")&&pSC) {
		Set tInfo = $$$Text("Deployment token taken out.")_" "_$$$Text("Token for Machine")_": "_$G(pTargetInfo("Machine"))_", "_$$$Text("Instance")_": "_$G(pTargetInfo("Instance"))_", "_$$$Text("Namespace")_": "_$G(pTargetInfo("Namespace"))
		$$$OutputDeployLog(tInfo)
		Set tDeploymentToken.Username = $Username
		Set tDeploymentToken.ForcedClearUser = ""
		Set tDeploymentToken.Job = $Job
		Set tDeploymentToken.OpenedTime = $$$timeUTC
		Set tDeploymentToken.SourceMachine = $G(pSourceInfo("Machine"))
		Set tDeploymentToken.SourceInstance = $G(pSourceInfo("Instance"))
		Set tDeploymentToken.SourceNamespace = $G(pSourceInfo("Namespace"))
		Set tDeploymentToken.SourceProduction = $G(pSourceInfo("SourceProduction"))
		/* Reset target in case DB moved */
		Set tDeploymentToken.TargetMachine = pTargetInfo("Machine")
		Set tDeploymentToken.TargetInstance = pTargetInfo("Instance")
		Set tDeploymentToken.TargetNamespace = pTargetInfo("Namespace")		
		Set pSC = tDeploymentToken.%Save()
		If $$$ISERR(pSC) {
					Set tInfo = $$$Text("Failed to save new Deployment token for this namespace after setting user and job.")
					$$$OutputDeployLog(tInfo)
					Set tInfoErr = $$$ERROR($$$EnsErrGeneral,tInfo)
					Set pSC = $$$ADDSC(pSC,tInfoErr)
		} 
	}
	Quit tDeploymentToken
}

/// Initialise DeploymentToken and create Deployment Invocation Object
ClassMethod InitDeploymentToken(ByRef pDeploymentToken As Ens.Deployment.Token, pFilename As %String = "", pTargetProduction As %String = "", Output pSC As %Status) As Ens.Deployment.Invocations
{
	Set pSC = $$$OK,tDeploymentInvocation = $$$NULLOREF
	Try {
		Set pDeploymentToken.StartTime = ""
		Set pDeploymentToken.EndTime = ""
		Set pDeploymentToken.SystemStart = ##class(Ens.Deployment.Utils).getSystemStartTime()
		Set tDeploymentInvocation = ##class(Ens.Deployment.Invocations).%New()
		Set tDeploymentInvocation.Username = $Username
		Set tDeploymentInvocation.Job = $Job
		Set tDeploymentInvocation.TargetMachine = pDeploymentToken.TargetMachine
		Set tDeploymentInvocation.TargetInstance = pDeploymentToken.TargetInstance
		Set tDeploymentInvocation.TargetNamespace = pDeploymentToken.TargetNamespace
		Set tDeploymentInvocation.SourceMachine = pDeploymentToken.SourceMachine 
		Set tDeploymentInvocation.SourceInstance = pDeploymentToken.SourceInstance
		Set tDeploymentInvocation.SourceNamespace = pDeploymentToken.SourceNamespace
		Set tDeploymentInvocation.SourceProduction = pDeploymentToken.SourceProduction
		Set tDeploymentInvocation.DeploymentFilename = pFilename
		Set tDeploymentInvocation.TargetProduction = pTargetProduction
		Set pSC = tDeploymentInvocation.%Save()
		Quit:$$$ISERR(pSC)
		Set pDeploymentToken.InvocationId = tDeploymentInvocation.%Id()
		Set pSC = pDeploymentToken.%Save()
	} Catch ex {
		Set pSC = ex.AsStatus()
	}
	Set tInfo = $S($$$ISERR(pSC):$$$Text("Failed to initialize"),1:$$$Text("Initialized"))_" "_$$$Text("deployment token and invocation object.")
	$$$OutputDeployLog(tInfo)
	Quit tDeploymentInvocation
}

/// Record if this is a rollback
ClassMethod RecordIfRollback(pRollbackFilename As %String, pDeploymentNotesVDOC As %RegisteredObject, ByRef pDeploymentToken As Ens.Deployment.Token, ByRef pDeploymentInvocation As Ens.Deployment.Invocations, Output pIsARollback As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tRollbackforDeploymentFile = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/RollbackFor")
		If (tRollbackforDeploymentFile = "") {
			Set pIsARollback = 0
			Quit
		} Else { 
			Set pIsARollback = 1
			Set tOriginalRollbackFilename = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/OriginalRollbackFilename")
		}
		Set pDeploymentToken.IsARollback = 1
		Set tSC = pDeploymentToken.%Save()
		Quit:$$$ISERR(tSC)
		Set pDeploymentInvocation.ThisIsARollback = 1
		Set pDeploymentInvocation.RollbackFor = $S($L(tRollbackforDeploymentFile)>128:$E(tRollbackforDeploymentFile,1,128),1:tRollbackforDeploymentFile)
		Set tSC = pDeploymentInvocation.%Save()
		Quit:$$$ISERR(tSC)
		/* look for id of matching deployment file. Maybe more than one with the same deployment filename but rollback name needs to be unique*/
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare("SELECT ID FROM Ens_Deployment.Invocations WHERE DeploymentRollbackFilename = ?")
		Quit:$$$ISERR(tSC)
		Set tResults = tStatement.%Execute(tOriginalRollbackFilename)
		If tResults.%Next() {
			Set pDeploymentInvocation.RollbackForId = tResults.ID
			Set tSC = pDeploymentInvocation.%Save()
		}	
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Record completion of rollback
ClassMethod RecordEndOfRollback(ByRef pDeploymentInvocation As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Quit:(pDeploymentInvocation.RollbackForId = "")
		Set tRolledbackInvocation = ##class(Ens.Deployment.Invocations).%OpenId(pDeploymentInvocation.RollbackForId,,.tSC)
		If $IsObject(tRolledbackInvocation) {
			Set tRolledbackInvocation.RolledbackById = pDeploymentInvocation.%Id()
			Set tRolledbackInvocation.RolledbackBy = $S($L(pDeploymentInvocation.DeploymentFilename)>128:$E(pDeploymentInvocation.DeploymentFilename,1,128),1:pDeploymentInvocation.DeploymentFilename)
			Set tSC = tRolledbackInvocation.%Save()
		}
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Close DeploymentToken and Deployment Invocation Object
/// While InProgress is set no other deployment to the given namespace can take place.
ClassMethod CloseDeploymentTokenAndInvocation(ByRef pDeploymentToken As %RegisteredObject, ByRef pDeploymentInvocation As %RegisteredObject, pCompletedSuccessfully As %Boolean, pReverted As %Boolean = 0, pLogFile As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		If pCompletedSuccessfully {
			Set pDeploymentToken.InProgress = 0
			Set pDeploymentInvocation.Completed = 1
			Set pDeploymentInvocation.InProgress = 0
			Set:(pDeploymentInvocation.LastStatus = "") pDeploymentInvocation.LastStatus = 1
		} Else {
			If pReverted {
				Set pDeploymentToken.InProgress = 0
				Set pDeploymentInvocation.InProgress = 0
				Set tInfo =$$$Text("Clearing InProgress flag and marking the deployment as reverted.")
				$$$OutputDeployLog(tInfo)
				
			} Else {
				If pDeploymentToken.InProgress {
					Set tInfo =$$$Text("Leaving the deployment marked as InProgress since did not complete successfully.")
					$$$OutputDeployLog(tInfo)
					Set tInfo = $$$Text("Go to the Deployment History page to review and clear in progress flag.")
					$$$OutputDeployLog(tInfo)
				}
			}
		}
		Set pDeploymentToken.EndTime = $$$timeUTC
		Set pDeploymentInvocation.EndTime = $$$timeUTC
		If ((pLogFile '= "") && (##class(%File).Exists(pLogFile))){
			Try {
				Set pDeploymentInvocation.DeploymentLogFileStream = ##class(%Stream.GlobalCharacter).%New()
				Set tLogStream = ##class(%Stream.FileCharacter).%New()
				Do tLogStream.LinkToFile(pLogFile)  
				Do pDeploymentInvocation.DeploymentLogFileStream.CopyFromAndSave(tLogStream)
			} Catch (exLog) {Set pDeploymentInvocation.DeploymentLogFileStream = ""}
		}
		Set tSC = pDeploymentInvocation.%Save()
		Quit:$$$ISERR(tSC)
		Set tSC = pDeploymentToken.%Save()
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set tInfo = $S($$$ISERR(tSC):$$$Text("Failed to close"),1:$$$Text("Closed"))_" "_$$$Text("deployment token and deployment invocation object.")
	$$$OutputDeployLog(tInfo)
	Quit tSC
}

/// Record in the deployment invocation object the errors and if reverted. 
ClassMethod RecordDeploymentInvocationError(ByRef pDeploymentToken As %RegisteredObject, ByRef pDeploymentInvocation As %RegisteredObject, pSC As %Status, pSingleFailure As %String, pRequiresManualIntervention As %String, pReverted As %Boolean) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pDeploymentInvocation.Completed = 0
		Set pDeploymentInvocation.LastStatus = pSC
		Set pDeploymentInvocation.SingleFailure = $S($L(pSingleFailure)>512:$E(pSingleFailure,1,512),1:pSingleFailure)
		Set pDeploymentInvocation.RequiresManualIntervention = $S($L(pRequiresManualIntervention)>512:$E(pRequiresManualIntervention,1,512),1:pRequiresManualIntervention)
		Set:(pRequiresManualIntervention = "") pDeploymentInvocation.Reverted = pReverted
		Set tSC = pDeploymentInvocation.%Save()
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod ValidateDeploymentToken(ByRef pDeploymentToken As %RegisteredObject, ByRef pDeploymentInvocation As %RegisteredObject) As %Status
{
	Set tSC = $$$OK,tText = ""
	Try {
		Set:(pDeploymentToken.InProgress '= 0) tText = tText_$$$Text("Deployment Token marked as InProgress. ")
		Set:(pDeploymentToken.Username '= $Username) tText = tText_$$$Text("Deployment Token taken out by different User. ")
		Set:(pDeploymentToken.Job '= $Job) tText = tText_$$$Text("Deployment Token taken out in a different Job. ")
		Set tMachineInstance = ##class(%SYS.System).GetUniqueInstanceName()
		Set tMachine = $P(tMachineInstance,":",1)
		Set tInstance = $P(tMachineInstance,":",2)
		Set pTargetInfo("Namespace") = $SYSTEM.SYS.NameSpace()
		Set:(pDeploymentToken.TargetNamespace '= $SYSTEM.SYS.NameSpace()) tText = tText_$$$Text("Deployment Token taken out for a different Namespace. ")
		Set:(pDeploymentToken.TargetMachine '= tMachine) tText = tText_$$$Text("Deployment Token taken out for a different Machine. ")
		Set:(pDeploymentToken.TargetInstance '= tInstance) tText = tText_$$$Text("Deployment Token taken out for a different Instance. ")
		Set:(pDeploymentToken.InvocationId '= pDeploymentInvocation.%Id()) tText = tText_$$$Text("Deployment Token and Invocation object do not match. ")
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set:(tText '="") tSC = $$$ERROR($$$EnsErrGeneral,tText)
	Quit tSC
}

/// Checks if the Deployment token object for this namespace is held open.
/// To reduce delay if it is in use the lock timeout is reduced to 2 seconds whilst testing.
ClassMethod IsDeploymentTokenUnlocked() As %Boolean
{
	Set tSysLockTimeout = $SYSTEM.SQL.SetProcessLockTimeout(2) /* reduce lock time out for waiting */
	Set tStatus=##class(Ens.Deployment.Token).TargetIDCheck("DeployToken",1)
	Do $SYSTEM.SQL.SetProcessLockTimeout(tSysLockTimeout)
	Quit ''tStatus
}

/// Checks if the Deployment token object for this namespace is marked as InProgress
/// whether or not the deployment token object is locked.
ClassMethod IsDeploymentTokenInProgress(Output pUsername As %String = "", Output pJob As %String = "", Output pSC As %Status) As %Integer
{
	Try {
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSQL = "SELECT InProgress,Username,Job FROM Ens_Deployment.Token WHERE ID = ?"
		Set pSC = tStatement.%Prepare(tSQL)
		Quit:$$$ISERR(pSC)
		Set tResult = tStatement.%Execute("DeployToken")
		Quit:$$$ISERR(pSC)
		If tResult.%Next() {
			Set tInProgress = tResult.InProgress, pUsername = tResult.Username, pJob = tResult.Job
		} Else {
			Set tInProgress = 0	
		} 		
	} Catch ex {
		Set pSC = ex.AsStatus()
	}	
	Set:$$$ISERR(pSC) tInProgress = -1
	Quit tInProgress
}

ClassMethod RecordStartDeploymentToken(ByRef pDeploymentToken As %RegisteredObject, ByRef pDeploymentInvocation As %RegisteredObject, pTargetProduction As %String, pFilename As %String, pRollbackFilename As %String, pLogFile As %String, pAutoRevert As %Boolean) As %Status
{
	Set tSC = $$$OK,tText = ""
	Try { 
		Set tSC = ..ValidateDeploymentToken(pDeploymentToken,pDeploymentInvocation)
		Quit:($$$ISERR(tSC))
		Set pDeploymentToken.InProgress = 1
		Set pDeploymentToken.StartTime = $$$timeUTC
		Set pDeploymentToken.TargetProduction = pTargetProduction
		Set pDeploymentInvocation.TargetProduction = pTargetProduction
		Set pDeploymentInvocation.InProgress = 1
		Set pDeploymentInvocation.StartTime = $$$timeUTC
		Set pDeploymentInvocation.CalledWithAutoRevert = pAutoRevert
		Set pDeploymentInvocation.DeploymentFilename = pFilename
		Set pDeploymentInvocation.DeploymentRollbackFilename = pRollbackFilename
		Set pDeploymentInvocation.DeploymentLogFilename = pLogFile
		Set tSC = pDeploymentInvocation.%Save()
		Quit:$$$ISERR(tSC)
		Set tSC = pDeploymentToken.%Save()
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Clear DeploymentToken and Deployment Invocation Object
/// InProgress flag
ClassMethod ClearDeploymentInProgressFlag() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tDeploymentToken = ##class(Ens.Deployment.Token).%OpenId("DeployToken",4,.tSC)
		Quit:($$$ISERR(tSC))
		Set tDeploymentInvocation = ##class(Ens.Deployment.Invocations).%OpenId(tDeploymentToken.InvocationId,,.tSC)
		Quit:($$$ISERR(tSC))
		Set tInfo = $$$Text("Opened deployment token and invocation object to force clear")
		$$$OutputDeployLog(tInfo)
		Set tDeploymentToken.ForcedClearUser = $Username
		Set tDeploymentInvocation.ForcedClearUser = $Username
		Set tSC = ..CloseDeploymentTokenAndInvocation(tDeploymentToken,tDeploymentInvocation,1)
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set tInfo = $S($$$ISERR(tSC):$$$Text("Failed"),1:"Succeeded")_" "_$$$Text("in clearing deployment token and deployment invocation object InProgress flag.")
	$$$OutputDeployLog(tInfo)
	Quit tSC
}

/// Carry out necessary checks before requesting the deployment token
/// Converts DeploymentFile to XMLVDoc
/// Extracts EnsExportNotes to XMLVDoc
/// Checks if allowed to deploy to same as source(note needed when applying a rollback
/// Checks if the rollback file either exists if not doing a rollback or if does not exist if doing a rollback
ClassMethod PreDeploymentTokenChecks(pDeploymentFile As %String, pRollbackFilename As %String, pCreateRollback As %Boolean, pAllowDeployToSource As %Boolean, Output pDeploymentVDOC As %RegisteredObject, Output pDeploymentNotesVDOC As %RegisteredObject, Output pSourceInfo As %String, Output pTargetInfo As %String) As %Status
{
	Set tSC = ..GeneratePackageXMLVDOC(pDeploymentFile,.pDeploymentVDOC)
	Goto:$$$ISERR(tSC) Exit
	Set tSC = ..GeneratePTDXMLVDOC(pDeploymentFile,pDeploymentVDOC,"EnsExportNotes", .pDeploymentNotesVDOC)
	If pDeploymentNotesVDOC.GetValueAt("/1/name()") = "Error" {
		Set tInfo = $$$Text("Not a deployment file. Missing EnsExportNotes.")
		$$$OutputDeployLog(tInfo)
		Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
	}
	If $$$ISERR(tSC) Goto Exit
	Set tSC = ..GetSourceInfo(pDeploymentNotesVDOC,.pSourceInfo)
	If $$$ISERR(tSC) Goto Exit
	Set tSC = ..GetTargetInfo(.pTargetInfo)
	If $$$ISERR(tSC) Goto Exit
	If ..CheckSourceAndTargetSame(.pSourceInfo,.pTargetInfo) {	
		If 'pAllowDeployToSource {
			Set tInfo = $$$Text("DeployCode() API was called not allowing deployment to the same target as the source.")
			$$$OutputDeployLog(tInfo)
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Goto Exit
		} Else {
			Set tInfo = $$$Text("Deploying to a target that is the same as the source.")
			$$$OutputDeployLog(tInfo)
		}
	}
	If (pRollbackFilename = "") {
		Set tInfo = $$$Text("A rollback filename has not been specified")
		$$$OutputDeployLog(tInfo)
		Set tSC =  $$$ERROR($$$EnsErrGeneral,tInfo)
		Goto Exit
	}
	If pCreateRollback {
		 If (##class(%File).Exists(pRollbackFilename)){
			Set tInfo = $$$Text("A rollback file already exists with name")_" "_pRollbackFilename
			$$$OutputDeployLog(tInfo)
			Set tSC =  $$$ERROR($$$EnsErrGeneral,tInfo)
			Goto Exit
		}
		If '##class(%File).DirectoryExists(##class(%File).GetDirectory(pRollbackFilename)) {
			Set tInfo = $$$Text("Directory for Rollback file")_" "_##class(%File).GetDirectory(pRollbackFilename)_" "_$$$Text("does not exist")
			$$$OutputDeployLog(tInfo)
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Goto Exit
		}
	} Else {
		 If ('##class(%File).Exists(pRollbackFilename)){
			Set tInfo = $$$Text("A rollback file does not exist with name")_" "_pRollbackFilename
			$$$OutputDeployLog(tInfo)
			Set tSC =  $$$ERROR($$$EnsErrGeneral,tInfo)
			Goto Exit
		}
	}
Exit
	Quit tSC
}

/// Move pDeploymentFile and pRollbackFile into stream storage of invocation object - ready to be able to get them back later if crash and move to a mirror.
ClassMethod StoreFilesinInvocationObject(ByRef pDeploymentInvocation As %RegisteredObject, pDeploymentFile As %String, pRollbackFilename As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pDeploymentInvocation.DeploymentFileStream = ##class(%Stream.GlobalBinary).%New()
		Set tDeploymentStream = ##class(%Stream.FileBinary).%New()
		Set tSC = tDeploymentStream.LinkToFile(pDeploymentFile)  Quit:($$$ISERR(tSC))
		Set tSC = pDeploymentInvocation.DeploymentFileStream.CopyFromAndSave(tDeploymentStream)  Quit:($$$ISERR(tSC))
		Set tDeploymentStream = ""
		Set pDeploymentInvocation.DeploymentRollbackFileStream = ##class(%Stream.GlobalBinary).%New()
		Set tRollbackStream = ##class(%Stream.FileBinary).%New()
		Set tSC = tRollbackStream.LinkToFile(pRollbackFilename)  Quit:($$$ISERR(tSC))
		Set tSC = pDeploymentInvocation.DeploymentRollbackFileStream.CopyFromAndSave(tRollbackStream)  Quit:($$$ISERR(tSC))
		Set tRollbackStream = ""
		Set tSC = pDeploymentInvocation.%Save()
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given 2 items report what changes are made to first item to make the
/// static values the same as the second item.  
ClassMethod CompareItems(pItem1 As %RegisteredObject, pItem2 As %RegisteredObject, Output pItem1SettingChanges As %String) As %Status
{
	Set tSC = $$$OK
	/* 
		The output is pItem1SettingChanges is an array:
								pItem1.Name,ChangeProperty,Name,Deploy & Current = Value
								pItem1.Name,[ChangeSetting,AddSetting,RemoveSetting],Name,Target,Deploy & Current [If ChangeSetting] = Value
		Go through each property in pItem2 and see what changes in pItem1.
		Go through each Setting in pItem2 and see what changes in pItem1 - either add or change
		Go through each setting in pItem1 and see if needs to be removed. 
	
			eConfigSettingValueTypeReadOnly    0
			eConfigSettingValueTypeProduction  1
			eConfigSettingValueTypeSystem      2
			eConfigSettingValueTypeProperty    3
			Set pColNames=$LB("IsAdapter","Name","Value","ValueSource","DefaultValue","DefaultSource","Description","DataType","MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST","IsRequired","LocalizedName","Category","LocalizedCategory","EditorContext")
			;"Core","Host","Adapter"||PropName||Value||0,1,2 or 3
			
			Change no matter where from provided not read only... && ($LG(tSettingsList(tSettingNum),4) = $$$eConfigSettingValueTypeProperty)
		*/
	
	Set tSC = pItem1.GetStaticSettings(.tSettingsList)

	Set tSettingNum = $O(tSettingsList(""))
	While (tSettingNum '= "") {			
		If (($LG(tSettingsList(tSettingNum),1) = "Core") && ($LG(tSettingsList(tSettingNum),4) '= $$$eConfigSettingValueTypeReadOnly)) {	
			Set tProperty = $LG(tSettingsList(tSettingNum),2)
			Set:($LG(tSettingsList(tSettingNum),3) '= $PROPERTY(pItem2,tProperty)) pItem1SettingChanges(pItem1.Name,"ChangeProperty",tProperty,"Deploy") = $PROPERTY(pItem2,tProperty),pItem1SettingChanges(pItem1.Name,"ChangeProperty",tProperty,"Current") = $LG(tSettingsList(tSettingNum),3)
		}
		Set tSettingNum = $O(tSettingsList(tSettingNum))
	}
	
	Try {
		For i=1:1:pItem2.Settings.Count() {
			Set tSetting2 = pItem2.Settings.GetAt(i)
			Set tTarget2 = tSetting2.Target
			Set tName2 = tSetting2.Name
			Set tSetting1 = pItem1.FindSettingByName(tName2, tTarget2)
			If $IsObject(tSetting1) {
				If (tSetting2.Value '= tSetting1.Value) {
					Set pItem1SettingChanges(pItem2.Name,"ChangeSetting",tName2,tTarget2,"Deploy") = tSetting2.Value
					Set pItem1SettingChanges(pItem2.Name,"ChangeSetting",tName2,tTarget2,"Current") = tSetting1.Value
				}
			} Else {
				Set pItem1SettingChanges(pItem2.Name,"AddSetting",tName2,tTarget2)=tSetting2.Value
			}
		}
	}	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit:$$$ISERR(tSC) tSC

	Try {
		For i=1:1:pItem1.Settings.Count() {
			Set tSetting1 = pItem1.Settings.GetAt(i)
			Set tTarget1 = tSetting1.Target
			Set tName1 = tSetting1.Name
			Set tSetting2 = pItem2.FindSettingByName(tName1, tTarget1)
			If '$IsObject(tSetting2) {
				Set pItem1SettingChanges(pItem1.Name,"RemoveSetting",tName1,tTarget1)=tSetting1.Value
			}
		}
	}	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Get deployment source information from the deployment notes
ClassMethod GetSourceInfo(pDeploymentNotesVDOC As %RegisteredObject, Output pSourceInfo As %String) As %Status
{
	Set tSC = $$$OK
	Try {	
		Set pSourceInfo("Machine") = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/Machine")
		Set pSourceInfo("Instance") = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/Instance")
		Set pSourceInfo("Namespace") = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/Namespace")
		Set pSourceInfo("SourceProduction") = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/SourceProduction")	
		Set pSourceInfo("ProductionClassInExport") = pDeploymentNotesVDOC.GetValueAt("/Deployment/ProductionClassInExport")           
		Set pSourceInfo("Username") = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/Username")
		Set pSourceInfo("UTC") = pDeploymentNotesVDOC.GetValueAt("/Deployment/Creation/UTC")
		Set tCount = pDeploymentNotesVDOC.GetValueAt("/Deployment/Notes/*")
		Set pSourceInfo("Notes")=tCount
		For tC = 1:1:tCount {
			Set pSourceInfo("Notes",tC)=$ZCVT(pDeploymentNotesVDOC.GetValueAt("/Deployment/Notes/"_tC),"I","XML")
		}
	} Catch ex { Set tSC = ex.AsStatus() }
	Quit tSC
}

/// Get deployment target system information
/// The target production might be changed at deployment
ClassMethod GetTargetInfo(Output pTargetInfo As %String) As %Status
{
	Set tSC = $$$OK
	Try {	
		Set tMachineInstance = ##class(%SYS.System).GetUniqueInstanceName()
		Set tMachine = $P(tMachineInstance,":",1)
		Set tInstance = $P(tMachineInstance,":",2)
		Set pTargetInfo("Machine") = tMachine
		Set pTargetInfo("Instance") = tInstance
		Set pTargetInfo("Namespace") = $SYSTEM.SYS.NameSpace()
		Set pTargetInfo("Production") = ##class(Ens.Director).GetActiveProductionName() 
		Set pTargetInfo("Username") = $USERNAME
		Set pTargetInfo("UTC") = $$$timeUTC
	} Catch ex { Set tSC = ex.AsStatus() }
	Quit tSC
}

/// Returns true if the deployment source machine, instance and production are the same as the deployment target machine,instance and production
ClassMethod CheckSourceAndTargetSame(ByRef pSourceInfo As %String, ByRef pTargetInfo As %String) As %Boolean
{
	Quit ($G(pTargetInfo("Machine"))=$G(pSourceInfo("Machine"))) && ($G(pTargetInfo("Instance"))=$G(pSourceInfo("Instance"))) && ($G(pTargetInfo("Namespace"))=$G(pSourceInfo("Namespace")))
}

/// Applies the rollback of the last deployment started.
ClassMethod RollbackLastDeployment(pDeploymentFile As %String = "", pRollbackFilename As %String = "", pLogFile As %String = "", pWhereToLog As %String = "LHEI", pAutoRevert As %Boolean = 0)
{
	Set tSC = $$$OK
	Try {
		Set tInvocationId = ..GetLastDeploymentInvocationId(.tSC)
		Quit:($$$ISERR(tSC))
		If (tInvocationId = "") {
			Set tSC = $$$ERROR($$$EnsErrGeneral,$$$Text("No previous deployment to rollback"))
			Quit
			}
		Set tInvocation = ##class(Ens.Deployment.Invocations).%OpenId(tInvocationId,,.tSC)
		Quit:($$$ISERR(tSC))
		Set tTargetProduction = tInvocation.TargetProduction
		Set tNeedRollback = 1
		Set tDeploymentFileFromInput = ##class(%Stream.FileBinary).%New()
		If (pDeploymentFile = "") {
			Set tPriorDeploymentFile = tInvocation.DeploymentFilename
			Set tDeployDirectory = ##class(%File).GetDirectory(tPriorDeploymentFile,1)
			Set tDeployFile = ##class(%File).GetFilename(tPriorDeploymentFile)
			If '##class(%File).DirectoryExists(tDeployDirectory) {
				Set tSCD = ##class(%File).CreateDirectory(tDeployDirectory)
				/* could be on a different system (mirror system) with different drives */
				Set tTempDeploymentFile = ##class(%File).TempFilename()
				Set tDeployDirectory = ##class(%File).GetDirectory(tTempDeploymentFile,1)
			}
			Set pDeploymentFile = tDeployDirectory_"Rollback_of_"_tDeployFile
		}
		Set tDeploymentFileFromInput.Filename = pDeploymentFile
		Set tSC = tDeploymentFileFromInput.CopyFromAndSave(tInvocation.DeploymentRollbackFileStream)
		Quit:($$$ISERR(tSC))
		Set tDeploymentFile = tDeploymentFileFromInput.Filename /* reset DeploymentFile to just a file name */
		Set tDeploymentFileFromInput = ""
		Do ##class(Ens.Deployment.Utils).GenerateFileNames(pDeploymentFile,.tRollbackFilename,.tLogFile,.tReportFile)
		Set:(pRollbackFilename="") pRollbackFilename = tRollbackFilename
		Set:(pLogFile="") pLogFile = tLogFile
		Set tAllowDeployToSource = 1
		Set tSC = ##class(Ens.Deployment.Deploy).DeployCode(pDeploymentFile,tTargetProduction,tNeedRollback,pRollbackFilename,pWhereToLog,pLogFile,tAllowDeployToSource,pAutoRevert) 
	} Catch (ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

ClassMethod GetLastDeploymentInvocationId(ByRef pSC As %Status) As %String
{
	Set pSC = $$$OK, tInvocationId = ""
	Try {
		Set tStatement = ##class(%SQL.Statement).%New()
		Set pSC = tStatement.%Prepare("SELECT ID, InvocationId FROM Ens_Deployment.Token Where ID = 'DeployToken'")
		Set tResults = tStatement.%Execute()
	} Catch (ex) {
		Set pSC = ex.AsStatus()
	}
	Quit:$$$ISERR(pSC) ""
	Set:(tResults.%Next()) tInvocationId = tResults.InvocationId
	Quit tInvocationId
}

}
