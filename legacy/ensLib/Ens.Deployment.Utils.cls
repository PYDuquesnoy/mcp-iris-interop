/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsDeploy

/// <class>Ens.Deployment.Utils</class> provides APIs to create deployment packages and is used with <class>Ens.Deployment.Deploy</class> or applied through the Portal.  <br> <br>
/// <!doctype html public "-//w3c//dtd html 4.0 transitional//en">
/// <html>
/// <head>
///    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
///    <meta name="GENERATOR" content="Mozilla/4.77 [en] (Windows NT 5.0; U) [Netscape]">
///    <title>Dynamic SQL</title>
/// </head>
/// 	<body>
/// 	<p>Examples:
/// 	</p>
/// 
/// <pre>
/// /* Create a deployment file from a Studio Project */
/// 	Set tProjectName = "HL7v2Driver"
/// 	Set tProductionName = "HL7v2Driver.SampleProduction"
/// 	Set tProductionClassIncluded = 1
/// 	Set tExportFilename = "/SomeDirectory/Deployment_"_tProjectName_".xml"
/// 	Set tComments =##class(%Stream.TmpCharacter).%New() /* tComments can be a stream or string */
/// 	Do tComments.WriteLine("This is a test exporting the whole production")
/// 	Do tComments.WriteLine("Created to show HL7 message generation")
/// 	Do tComments.Rewind()
/// 	Set tSC =##class(Ens.Deployment.Utils).CreateExportPackageFromProjectList(tProjectName,.tContentsList,tExportFilename,tProductionName,tComments,tProductionClassIncluded)
/// </pre><pre>	
/// /* Create a deployment file from a list of items */
/// 	Set tProjectName = "HL7v2Driver"
/// 	Set tProductionName = "HL7v2Driver.SampleProduction"
/// 	Set tProductionClassIncluded = 0
/// 	Set tExportFilename = "/SomeDirectory/Deployment_one_class_"_tProjectName_".xml"
/// 	Set tComments = "Exporting one class and one routine." 
/// 	Set tContentsList("HL7v2Gen.MAC")=""
/// 	Set tContentsList("HL7v2Driver.Service.CLS")=""
/// 	Set tSC =##class(Ens.Deployment.Utils).CreateExportPackageFromProjectList(tProjectName,.tContentsList,tExportFilename,tProductionName,tComments,tProductionClassIncluded)
/// </pre><pre>	
/// /* Create a Project text document containing settings for an Item */
/// 	Set tItemName = "ToMainLabADT"
/// 	Set tProjectName = "HL7v2Driver"
/// 	Set tProductionName = "HL7v2Driver.SampleProduction"
/// 	Set:(tItemName '[ "||") tItemName = tProductionName_"||"_tItemName
/// 	Set tItem = ##class(Ens.Config.Production).OpenItemByConfigName(tItemName)
/// 	If $IsObject(tItem) Set tSC = ##class(Ens.Deployment.Utils).CreatePTDFromItem(.tItem,.tPTDName)	
/// 	If tPTDName '= "" {
/// 		Set tProductionClassIncluded = 0
///  		Set tExportFilename = $$$DeployDirectory_"Deployment_item_"_tProjectName_".xml"
/// 		Set tComments = "just an item"
/// 		Set tContentsList(tPTDName_".PTD")=""
/// 		Set tSC =##class(Ens.Deployment.Utils).CreateExportPackageFromProjectList(tProjectName,.tContentsList,tExportFilename,tProductionName,tComments,tProductionClassIncluded)
/// 	}
/// 	Do ##class(Ens.Util.ProjectTextDocument).Delete(tPTDName_".PTD")
/// </pre><pre>	
/// /* Create a Project text document containing settings for a Production */
/// 	Set tProjectName = "HL7v2Driver"
/// 	Set tProductionName = "HL7v2Driver.SampleProduction"
/// 	Set tProduction = ##class(Ens.Config.Production).%OpenId(tProductionName)
/// 	If $IsObject(tProduction) Set tSC = ##class(Ens.Deployment.Utils).CreatePTDFromProduction(tProduction,.tPTDName)	
/// 	If tPTDName '= "" {
/// 		Set tProductionClassIncluded = 0
/// 		Set tExportFilename = "/SomeDirectory/Deployment_prod_settings_"_tProjectName_".xml"
/// 		Set tComments = "Production settings"
/// 		Set tContentsList(tPTDName_".PTD")=""
/// 		Set tSC =##class(Ens.Deployment.Utils).CreateExportPackageFromProjectList(tProjectName,.tContentsList,tExportFilename,tProductionName,tComments,tProductionClassIncluded)
/// 	}
/// 	Do ##class(Ens.Util.ProjectTextDocument).Delete(tPTDName_".PTD") /* Clean up tPTDName_".PTD" unless want to keep */
/// </pre><pre>	
/// /* 	Create a Project text document containing list of items to remove.
/// 	This can then be included in a call to CreateExportPackageFromProjectList()
/// 	To remove a busines host item create the PTD for that item first.
/// */
/// 	Set tItemName = "ToMainLabADT"
/// 	Set tProjectName = "HL7v2Driver"
/// 	Set tProductionName = "HL7v2Driver.SampleProduction"
/// 	Set:(tItemName '[ "||") tItemName = tProductionName_"||"_tItemName
/// 	Set tItem = ##class(Ens.Config.Production).OpenItemByConfigName(tItemName)
/// 	If $IsObject(tItem) Set tSC = ##class(Ens.Deployment.Utils).CreatePTDFromItem(.tItem,.tPTDName)	
/// 	If tPTDName '= "" {
/// 		Set tItemsToRemove(tPTDName_".PTD")=""
/// 		Set tSC =##class(Ens.Deployment.Utils).CreateExportRemovePTD(tProjectName,tProductionName,.tItemsToRemove,.tPTDNameRemove)	
/// 		If tPTDNameRemove '= "" {
/// 			Set tProductionClassIncluded = 0
/// 			Set tExportFilename = "/SomeDirectory/Deployment_remove_item_"_tProjectName_".xml"
/// 			Set tComments = "Remove one item but we could have included other items"
/// 			Set tContentsList(tPTDNameRemove_".PTD")=""
/// 			Set tSC =##class(Ens.Deployment.Utils).CreateExportPackageFromProjectList(tProjectName,.tContentsList,tExportFilename,tProductionName,tComments,tProductionClassIncluded)
/// 		}
/// 	}
/// 	Do ##class(Ens.Util.ProjectTextDocument).Delete(tPTDName_".PTD") /* Clean up tPTDName_".PTD" unless want to keep */
/// 	Do ##class(Ens.Util.ProjectTextDocument).Delete(tPTDNameRemove_".PTD") /* Clean up tPTDNameRemove_".PTD" unless want to keep */
/// </pre>
Class Ens.Deployment.Utils [ Abstract, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Used to retrieve contents of the export file by item number
/// Used in InterSystemsm IRIS code: Portal deployment interface.
ClassMethod GetItemContentsByItemNumber(pDeploymentFile As %String, pItemNumber As %Integer, Output pItemContents As %String, Output pName As %String, Output pExt As %String) As %Status
{
	Set tSC = $$$OK, pName = "", pExt = ""
	Set tSC1 = ##class(Ens.Deployment.Deploy).GeneratePackageXMLVDOC(pDeploymentFile,.tDeploymentVDOC) 
	If $$$ISERR(tSC1) {
		Set pItemContents = $$$Text("Unable to access item:")_pItemNumber_" "_$$$Text("from")_" "_pDeploymentFile_"("_$$$StatusDisplayString(tSC1)_")"
	} Else {
		Set pItemContents = tDeploymentVDOC.GetValueAt("/Export/"_pItemNumber_"/full()")
		Set pName = tDeploymentVDOC.GetValueAt("/Export/"_pItemNumber_"/@name")
		Set pExt = $P(pName,".",*)
		Set pName = $P(pName,".",1,*-1)
	} 
	Quit tSC
}

/// Generate rollback, log & report file names based on Deployment file name
/// Used in InterSystems IRIS code: Portal deployment interface.
ClassMethod GenerateFileNames(pDeploymentFile As %String, Output pRollbackFilename As %String, Output pLogFile As %String, Output pReportFile As %String, pAttempts As %Integer = 20)
{
	Set tSC = $$$OK
	Try {
		Set tDeployDirectory = ##class(%File).GetDirectory(pDeploymentFile,1) /* Keep terminator */
		Set tDeployFile = ##class(%File).GetFilename(pDeploymentFile)
		Set tMachineInstance = ##class(%SYS.System).GetUniqueInstanceName()
		Set tMachine = $P(tMachineInstance,":",1)
		Set tInstance = $P(tMachineInstance,":",2)
		Set tNamespace = $SYSTEM.SYS.NameSpace()
		Set tRollbackDirectory = ##class(%File).NormalizeDirectory(tDeployDirectory_tNamespace_"/rollbacks")
		If '##class(%File).DirectoryExists(tRollbackDirectory) {
			/* Deploy directory exists so we only need to check Namespace directory */
			Set tParentDirectory = ##class(%File).ParentDirectoryName(tRollbackDirectory)
			Do:'##class(%File).DirectoryExists(tParentDirectory) ##class(%File).CreateDirectory(tParentDirectory)
			Do ##class(%File).CreateDirectory(tRollbackDirectory)
		}
		Set tLogDirectory = ##class(%File).NormalizeDirectory(tDeployDirectory_tNamespace_"/logs")
		Do:('##class(%File).DirectoryExists(tLogDirectory)) ##class(%File).CreateDirectory(tLogDirectory)
		Set tLastDot = $LENGTH(tDeployFile)+2-$FIND($REVERSE(tDeployFile),".")
		Set tDeployFileRootAndDot = $E(tDeployFile,1,tLastDot)
		Set tDeployFileExtAndDot = $E(tDeployFile,tLastDot,*)
		Set tDeployFileRoot = $E(tDeployFile,1,tLastDot-1)
		Set pRollbackFilename = "",tC = 0
		While ((pRollbackFilename = "") && (tC < pAttempts)) {
			Set pRollbackFilename = tRollbackDirectory_"Rollback_for_"_tMachine_"_"_tInstance_"_"_tNamespace_"_"_tDeployFileRoot_$S(tC=0:"",1:"_v"_tC)_tDeployFileExtAndDot
			Set:(##class(%File).Exists(pRollbackFilename)) pRollbackFilename = "",tC = tC + 1
		}
		Set pLogFile = tLogDirectory_"Deployment-Log_"_tMachine_"_"_tInstance_"_"_tNamespace_"_"_tDeployFileRoot_$S(tC=0:"",1:"_v"_tC)_".log"		
		Set pReportFile = tLogDirectory_"Deployment-Report_"_tMachine_"_"_tInstance_"_"_tNamespace_"_"_tDeployFileRoot_$S(tC=0:"",1:"_v"_tC)_".txt"
	} Catch (ex) {
			Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Log information to combination of Console, Web, Event Log, File
/// pEventLogType is used to have variable control over Event log entry
/// types if the initial log where setting includes EI for Event Log Information
ClassMethod WriteDeployLog(pText As %String = "", pEventLogType As %String = "") As %Status
{
		/* 
			$$$GetDeployLogWhere
				"" - Do not write
				L - If pLogFile defined open for append and WriteLine(text)
				C - write line text to current device
				H - write html version of text to temporary global for retrieval by portal
				EI - write text to event log Info
				EW - write text to event log Warning
				EE - write text to event log Error
		*/
	Set tSC = $$$OK
	Try {
		Set tWhereToLog = $$$GetDeployLogWhere
		Set:(pEventLogType'="") tWhereToLog = $REPLACE(tWhereToLog,"EI","E"_pEventLogType)
		Set tLogFile = $$$GetDeployLogFile
		Write:(tWhereToLog["C") !,$$$timeLocal_": "_pText
		If (tWhereToLog["H") {
			Try {
				Set @%TempPortalNode@("Log",$I(@%TempPortalNode@("Log"))) = $$$timeLocal_": "_$ZCVT(pText,"O","HTML")
			} Catch (ex) {}
		}
		If (tWhereToLog["EI") $$$LOGINFO(pText)
		If (tWhereToLog["EW") $$$LOGWARNING(pText)
		If (tWhereToLog["EE") $$$LOGERROR(pText)
		If ((tWhereToLog["L") && (tLogFile '="")) {
			Set tDebugInfo = ""
			If tWhereToLog["D" Set tDebugInfo = "[$S="_$S_"] "
			Set tFile = ##class(%Stream.FileCharacter).%New()
			Do tFile.LinkToFile(tLogFile)
			Do tFile.MoveToEnd()
			Do tFile.WriteLine($$$timeLocal_": "_tDebugInfo_pText)
			Do tFile.%Save()
		}
	} Catch (ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

ClassMethod getSystemStartTime() As %Integer
{
	Try {
		Set tNow = $$$timeUTCH
		Set tUpTime = $ZH
		Set tNowDays = $P(tNow,",",1)
		Set tNowSecs = $P(tNow,",",2)
		Set tNowDaysTotalSecs = tNowDays * 86400 + tNowSecs
		Set tStart = $NUMBER((tNowDaysTotalSecs - tUpTime),-1)
	} Catch ex {
		Set tStart = -1
	}
	Quit tStart
}

/// Retrieve User Document Extensions and their associated Document Classes.
ClassMethod getUserDocumentExts(pUserDocumentExts As %String)
{
	Try {
		Do StudioDocument^%SYS.cspServer2(.tIdocument)
		Set tIcls = ""
		For  {
			Set tIcls=$order(tIdocument(tIcls)) Quit:tIcls=""
			Set tIext=""
			For  {
				Set tIext=$order(tIdocument(tIcls,tIext)) Quit:tIext=""
				Set pUserDocumentExts(tIext)=tIcls
			}
		}
	} catch ex {}
}

/// Create a Project Document Text entry for a given Production Item.
ClassMethod CreatePTDFromItem(pItem As %RegisteredObject, Output pPTDName) As %Status
{
	Set tSC = $$$OK
	Try {
		Set xml = ##class(%Stream.GlobalCharacter).%New()
		Set tSC=pItem.XMLExportToStream(xml)  Quit:$$$ISERR(tSC)
		Do xml.Rewind()
		Set pPTDName="Settings:"_pItem.Name
		Do:##class(%RoutineMgr).Exists(pPTDName_".PTD") ##class(%RoutineMgr).Delete(pPTDName_".PTD") 
		Set tSC = ##class(Ens.Util.ProjectTextDocument).Create(xml,pPTDName,"Settings for "_pItem.Name_" in Production "_pItem.Production.Name)	
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Create a Project Document Text for Production Settings
/// This includes the production defined settings only and also does not include
/// Items or SubProductions.
ClassMethod CreatePTDFromProduction(pProduction As %RegisteredObject, Output pPTDName) As %Status
{
	Set tSC = $$$OK
	Try {
		Set xml = ##class(%Stream.GlobalCharacter).%New()
		Set pXDataHolderClassname = pProduction.Name
		Set pXDataName = "ProductionDefinition"
 		Set tCC = ##class(%Dictionary.CompiledClass).%OpenId(pXDataHolderClassname,0,.tSC)  
 		Quit:$$$ISERR(tSC)
		Set tIndex = tCC.XDatas.FindObjectId(pXDataHolderClassname_"||"_pXDataName)
		Try {
			Kill %objlasterror /* If the production definition is locked by another process then %objlasterror will be set and tXData will be empty */
			Set tXData = tCC.XDatas.GetAt(tIndex)
			If $D(%objlasterror){
				Set tSC = %objlasterror
				Quit
			}
			Set tStream = tXData.Data
		} Catch ex {
			Set tInfo = $$$Text("Failed to get current production definition. Check if being edited in another process.")
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Set tSC = $$$ADDSC(tSC, ex.AsStatus())
		}
		Quit:$$$ISERR(tSC)
		Do tStream.Rewind()
		Set tXMLVDoc = ##class(EnsLib.EDI.XML.Document).%New(tStream)
		For tToRemove = "Item","SubProduction" {
			Set tCount = tXMLVDoc.GetValueAt("/Production/"_tToRemove_"[*]")
			For tC = 1:1:tCount{
				Set tSC = tXMLVDoc.SetValueAt("","/Production/"_tToRemove_"[1]","remove")
				Quit:($$$ISERR(tSC))
			}	
		}
		Do tXMLVDoc.OutputToLibraryStream(.xml)
		Do xml.Rewind()
		Set pPTDName="ProductionSettings:"_pProduction.Name
		Do:##class(%RoutineMgr).Exists(pPTDName_".PTD") ##class(%RoutineMgr).Delete(pPTDName_".PTD") 
		Set tSC = ##class(Ens.Util.ProjectTextDocument).Create(xml,pPTDName,"Settings for production "_pProduction.Name)	
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Create a deployment Export Notes Project Text Document
/// pProjectName is a name given to the export project. The notes PTD will be this preceded by EnsExportNotes. The name does not include the .PTD extension.
/// pSourceProduction is the name of the Source production for the notes.
/// pComments is a stream of comments.
/// pContentsList is an array of items that will be exported by a subsequent process.
/// pProductionClassIncluded indicates if the export will include a Production class.
/// pRollbackFilename if specified indicates that these are notes for a rollback deployment file. This is passed by the deployment process.
/// pDeploymentFile if pRollbackFilename is specified then this is the name of the corresponding deployment file.
ClassMethod CreateExportNotesPTD(pProjectName As %String, pSourceProduction As %String, pComments As %Stream.Object = "", ByRef pContentsList As %String, pProductionClassIncluded As %Boolean = 0, Output pPTDName, pRollbackFilename As %String = "", pDeploymentFile As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set pPTDName="EnsExportNotes."_pProjectName
		Set:($L(pPTDName)>64) pPTDName = $E(pPTDName,1,64)
		Set tNotes = ##class(%Stream.GlobalCharacter).%New()
		Set tMachineInstance = ##class(%SYS.System).GetUniqueInstanceName()
		Set tMachine = $P(tMachineInstance,":",1)
		Set tInstance = $P(tMachineInstance,":",2)
		Do tNotes.WriteLine("<Deployment>")
		Do tNotes.WriteLine("<Creation>")
		Do tNotes.WriteLine("<Machine>"_tMachine_"</Machine>")
		Do tNotes.WriteLine("<Instance>"_tInstance_"</Instance>")
		Do tNotes.WriteLine("<Namespace>"_$SYSTEM.SYS.NameSpace()_"</Namespace>")
		Do tNotes.WriteLine("<SourceProduction>"_pSourceProduction_"</SourceProduction>")
		Do tNotes.WriteLine("<Username>"_$USERNAME_"</Username>")
		Do tNotes.WriteLine("<UTC>"_$$$timeUTC_"</UTC>")
		If (pRollbackFilename '= "") {
			Do tNotes.WriteLine("<RollbackFor>"_pDeploymentFile_"</RollbackFor>")
			Do tNotes.WriteLine("<OriginalRollbackFilename>"_pRollbackFilename_"</OriginalRollbackFilename>")
		}
		Do tNotes.WriteLine("</Creation>" )
		Do tNotes.WriteLine("<Notes>")
		If ('$IsObject(pComments) && (pComments '="")) {
			Set tempComments = pComments
			Set pComments = ##class(%Stream.TmpCharacter).%New()
			Do pComments.Write(tempComments)
		}
		If $IsObject(pComments) {
			Try {
				Do pComments.Rewind()
				If pComments.Size > 0 {
					Set c = 1
					While 'pComments.AtEnd {
						Set tExportNotes = pComments.ReadLine()
						Do tNotes.WriteLine("<Line num="_$C(34)_c_$C(34)_">"_$ZCVT(tExportNotes,"O","XML")_"</Line>")
						Set c = c + 1 
					}	
				}
			} Catch ex {}
		}
		Do tNotes.WriteLine("</Notes>")
		Do tNotes.WriteLine("<Contents>")
		Do tNotes.WriteLine("<ExportProject>"_pProjectName_"</ExportProject>")
		Set k=$O(pContentsList("")),c=1 
		While k '=""{
				Do tNotes.WriteLine("<Item num="_$C(34)_c_$C(34)_">"_k_"</Item>") 
				Set k=$O(pContentsList(k)),c=c+1
		}
		Do tNotes.WriteLine("</Contents>")
		Do tNotes.Write("<ProductionClassInExport>"_$S(pProductionClassIncluded:$G(pSourceProduction),1:""))
		Do tNotes.WriteLine("</ProductionClassInExport>")
		Do tNotes.WriteLine("</Deployment>")
		Do tNotes.Rewind()
		Do:##class(%RoutineMgr).Exists(pPTDName_".PTD") ##class(%RoutineMgr).Delete(pPTDName_".PTD") 
		Set tSC = ##class(Ens.Util.ProjectTextDocument).Create(tNotes,pPTDName,"Export Notes for export "_pProjectName)
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Create a deployment Export Items to Remove Project Text Document
/// If pPTDName is passed back "" then no PTD created as nothing to remove. The name does not include the .PTD extension.
/// pProjectName is a name given to the export project. The notes PTD will be this preceded by EnsExportNotes.
/// pSourceProduction is the name of the Source production for the notes.
/// pItemsToRemove is an array of items that will be added by the deployment and hence need to be marked for removal.
/// pRollbackFilename if specified indicates that these are notes for a rollback deployment file. This is passed by the deployment process.
/// pDeploymentFile if pRollbackFilename is specified then this is the name of the corresponding deployment file.
ClassMethod CreateExportRemovePTD(pProjectName As %String, pSourceProduction As %String, ByRef pItemsToRemove As %String, Output pPTDName, pRollbackFilename As %String = "", pDeploymentFile As %String = "") As %Status
{
	Set tSC = $$$OK, pPTDName = ""
	Try {
		If $D(pItemsToRemove) {
			Set tItemName = $O(pItemsToRemove(""))
			Set tCount = 0
			While tItemName '="" {
				If (($E(tItemName,1,14) = "EnsExportNotes") || ($E(tItemName,1,15) = "EnsExportRemove")){	
					Set tItemName = $O(pItemsToRemove(tItemName))
					Continue
				}
				Set tCount = tCount + 1
				If tCount = 1 {
					Set pPTDName="EnsExportRemove."_pProjectName
					Set:($L(pPTDName)>64) pPTDName = $E(pPTDName,1,64)
					Set tNotes = ##class(%Stream.GlobalCharacter).%New()
					Set tMachineInstance = ##class(%SYS.System).GetUniqueInstanceName()
					Set tMachine = $P(tMachineInstance,":",1)
					Set tInstance = $P(tMachineInstance,":",2)
					Do tNotes.WriteLine("<DeploymentRemoval>")
					Do tNotes.WriteLine("<Creation>")
					Do tNotes.WriteLine("<Machine>"_tMachine_"</Machine>")
					Do tNotes.WriteLine("<Instance>"_tInstance_"</Instance>")
					Do tNotes.WriteLine("<Namespace>"_$SYSTEM.SYS.NameSpace()_"</Namespace>")
					Do tNotes.WriteLine("<SourceProduction>"_pSourceProduction_"</SourceProduction>")
					Do tNotes.WriteLine("<Username>"_$USERNAME_"</Username>")
					Do tNotes.WriteLine("<UTC>"_$$$timeUTC_"</UTC>")
					If (pRollbackFilename '= "") {
						Do tNotes.WriteLine("<RollbackFor>"_pDeploymentFile_"</RollbackFor>")
						Do tNotes.WriteLine("<OriginalRollbackFilename>"_pRollbackFilename_"</OriginalRollbackFilename>")
					}
					Do tNotes.WriteLine("</Creation>" )
					Do tNotes.WriteLine("<ItemsToDelete>")			
				}
				Do tNotes.WriteLine("<Item num="_$C(34)_tCount_$C(34)_">"_tItemName_"</Item>")	
				Set tItemName = $O(pItemsToRemove(tItemName))
			}
			If (tCount > 0) {
				Do tNotes.WriteLine("</ItemsToDelete>")
				Do tNotes.WriteLine("</DeploymentRemoval>")
				Do tNotes.Rewind()
				Do:##class(%RoutineMgr).Exists(pPTDName_".PTD") ##class(%RoutineMgr).Delete(pPTDName_".PTD")
				Set tSC = ##class(Ens.Util.ProjectTextDocument).Create(tNotes,pPTDName,"List of items to delete "_pProjectName)
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Create a deployment Export package from a studio project
/// pProjectName is the name of the studio project or the name to be used if providing list in pContentsListArray
/// pContentsList - optional. An array of items to include in the export package.
/// 			If defined this is used and not the StudioProject.
/// 			If not defined then it is populated with the list of items from the project.
/// 		After completion the list will also include the temporary project and project text document created and exported.
/// pExportFilename is the OS file to create.
/// 			If not specified the file name will be generated as EnsExport-then the project name then a date timestamp in the current working directory.
/// pSourceProduction is the name of the Source production for the notes.
/// pComments is a stream of comments to include in the Export notes.
/// pProductionClassIncluded indicates if the export will include a Production class.
ClassMethod CreateExportPackageFromProjectList(pProjectName As %String, ByRef pContentsList, pExportFilename As %String = "", pSourceProduction As %String, pComments As %Stream.Object = "", pProductionClassIncluded As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If ('$IsObject(pComments) && (pComments '="")) {
			Set tempComments = pComments
			Set pComments = ##class(%Stream.TmpCharacter).%New()
			Do pComments.Write(tempComments)
			Do pComments.Rewind()
		}
		If '$D(pContentsList) {
			Set tSC = ..getProjectItemList(pProjectName,.pContentsList)
		}
		If '$D(pContentsList) {
			Set tSC = $$$ERROR($$$EnsErrGeneral,"No items to export.")
			Quit	
		}
		Set tSC =##class(Ens.Deployment.Utils).CreateExportNotesPTD(pProjectName,pSourceProduction,pComments,.pContentsList,pProductionClassIncluded,.tPTDName)
		Quit:'tSC
		Set pContentsList(tPTDName_".PTD")= ""
		/* Create Temporary Export Project to include in the export */
		Set tEnsProjectName="EnsExportAPI_"_pProjectName_"_"_$TR(##class(Ens.Util.Time).FormatDateTime("%Q%#z",,$$$timeUTC) , ".:","_-")
		Set tEnsDescription="Studio Project generated from IRIS comand line with source production of '"_pSourceProduction_"' at "_##class(Ens.Util.Time).FormatDateTime("%K(UTC)%Q UTC",,$$$timeUTC)
		Set:(pExportFilename="") pExportFilename="EnsExport-"_$Tr(pProjectName,".","_")_"-"_$ZStrip($ZDT($H,8),"*PC")_".xml"
		If ##class(%RoutineMgr).Exists(tEnsProjectName_".PRJ") {
			Set tSC=##class(%Studio.Project).Delete(tEnsProjectName)  
			Quit:$$$ISERR(tSC)&&'$$$StatusEquals(tSC,$$$DeleteObjectNotFound)
		}
		Set tSC = $$$OK /* reset possible 5810 error */
		Set tProject=##class(%Studio.Project).%New()
		If '$IsObject(tProject) {Set tSC = $$$ERROR($$$GeneralError,"Failed to create project object.") Quit}
		Set tProject.Name=tEnsProjectName
		Set tProject.Description=tEnsDescription
		Set tItem = $O(pContentsList(""))
		While (tItem '= ""){
			Do tProject.AddItem(tItem)
			Set tItem = $O(pContentsList(tItem))
		}
		Set tSC = tProject.%Save()
		Quit:$$$ISERR(tSC)
			
		Set pContentsList(tEnsProjectName_".PRJ")=""	
		Set tSC=$system.OBJ.Export(.pContentsList,pExportFilename,"-d")
		/* clean up even if the Export errors */
		Do ##class(Ens.Util.ProjectTextDocument).Delete(tPTDName_".PTD")
		Do ##class(%Studio.Project).%DeleteId(tEnsProjectName)	
		#;Kill pContentsList(tPTDName_".PTD")
		#;Kill pContentsList(tEnsProjectName_".PRJ")
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Loop through pDeployDetails("Items","") and find source control status.
/// Update information about the item.
ClassMethod SourceControlGetStatus(ByRef pDeployDetails As %String, Output pItemsAlreadyCheckedOut As %Boolean) As %Status
{
	Set tSC = $$$OK, pItemsAlreadyCheckedOut = 0
	Quit:'$IsObject($G(%SourceControl)) tSC
	Try {
		Set tItemName = $O(pDeployDetails("Items",""))
		While tItemName '= "" {
			If ($G(pDeployDetails("Items",tItemName,"ExistDate"),-1) '= -1) {
				Set tSC = %SourceControl.GetStatus(tItemName,.tIsInSourceControl,.tEditable,.tIsCheckedOut, .tUserCheckedOut)
				Quit:$$$ISERR(tSC)
				Set pDeployDetails("SourceControl",tItemName,"IsInSourceControl") = tIsInSourceControl
				Set pDeployDetails("SourceControl",tItemName,"Editable") = tEditable
				Set pDeployDetails("SourceControl",tItemName,"IsCheckedOut") = tIsCheckedOut
				Set:('pItemsAlreadyCheckedOut && tIsCheckedOut && (tUserCheckedOut '= $USERNAME)) pItemsAlreadyCheckedOut = 1
				Set pDeployDetails("SourceControl",tItemName,"UserCheckedOut") = tUserCheckedOut
				Set pDeployDetails("SourceControl",tItemName,"New") = 0
			} Else {
				Set pDeployDetails("SourceControl",tItemName,"New") = 1
			}
			Set tItemName = $O(pDeployDetails("Items",tItemName))
			
		}
	} Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

/// Loop through pObjectsToLoad and if item exists and is not in source control call AddToSourceControl
/// If the item does not yet exist in the system mark it to be added in pDeployDetails array.
ClassMethod SourceControlCheckOut(ByRef pObjectsToLoad, ByRef pDeployDetails As %String, Output pItemsAlreadyCheckedOut As %Boolean) As %Status
{
	Set tSC = $$$OK, pItemsAlreadyCheckedOut = 0
	Quit:'$IsObject($G(%SourceControl)) tSC
	Try {
		Set tItemName = $O(pObjectsToLoad(""))
		While tItemName '= "" {
			If (##class(%RoutineMgr).GetDate(tItemName) '= -1){
				Set tSC = %SourceControl.GetStatus(tItemName,.tIsInSourceControl,.tEditable,.tIsCheckedOut,.tUserCheckedOut)
				Quit:$$$ISERR(tSC)
				If 'tIsInSourceControl {
					Set tInfo = $$$Text("Adding")_" "_tItemName_" "_$$$Text("to source control from deployment invocation id")_": "_$G(pDeployDetails("InvocationId"))
					If pDeployDetails("Items",tItemName,"Type") '= "PTD" {
						$$$OutputDeployLog(tInfo)
						Set tSC = %SourceControl.AddToSourceControl(tItemName,tInfo)
						Quit:$$$ISERR(tSC)
					} Else {
						Set tInfo = $$$Text("Not")_" "_tInfo
						$$$OutputDeployLog(tInfo)
					}
				} ElseIf tIsCheckedOut {
					If (tUserCheckedOut '= $USERNAME) {Set pItemsAlreadyCheckedOut = 1 Quit}
				} Else {
					Set tInfo = $$$Text("Checking out")_" "_tItemName_" "_$$$Text("for deployment. Invocation id")_": "_$G(pDeployDetails("InvocationId"))
					$$$OutputDeployLog(tInfo)
					Set tSC = %SourceControl.CheckOut(tItemName,tInfo)
					Quit:$$$ISERR(tSC)
					Set tSC = %SourceControl.GetStatus(tItemName,.tIsInSourceControl,.tEditable,.tIsCheckedOut,.tUserCheckedOut)
					Quit:$$$ISERR(tSC)
					Set pDeployDetails("SourceControl",tItemName,"IsInSourceControl") = tIsInSourceControl
					Set pDeployDetails("SourceControl",tItemName,"Editable") = tEditable
					Set pDeployDetails("SourceControl",tItemName,"IsCheckedOut") = tIsCheckedOut
					Set pDeployDetails("SourceControl",tItemName,"UserCheckedOut") = tUserCheckedOut
				}
			} Else {
				Set pDeployDetails("SourceControl",tItemName,"ToBeAdded")=1
			}
			Set tItemName = $O(pObjectsToLoad(tItemName))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

/// Loop through pDeployDetails("SourceControl","") and for any item that is listed and GetStatus 
/// reports item checked out by this user then call CheckIn.
ClassMethod SourceControlCheckIn(ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK, pItemsAlreadyCheckedOut = 0
	Quit:'$IsObject($G(%SourceControl)) tSC
	Try {
		Set tItemName = $O(pDeployDetails("SourceControl",""))
		While tItemName '= "" {
			If ##class(%RoutineMgr).GetDate(tItemName) '= -1 { 
				Set tSC = %SourceControl.GetStatus(tItemName,.tIsInSourceControl,.tEditable,.tIsCheckedOut,.tUserCheckedOut)
				Quit:$$$ISERR(tSC)
				If tIsCheckedOut {
					If (tUserCheckedOut = $USERNAME) {
						Set tInfo = $$$Text("Checking in")_" "_tItemName_" "_$$$Text("following deployment. Invocation id")_": "_$G(pDeployDetails("InvocationId"))
						$$$OutputDeployLog(tInfo)
						Set tSC = %SourceControl.CheckIn(tItemName,tInfo)
						Quit:$$$ISERR(tSC)
					} Else {
						Set tInfo = $$$Text("Not checking in")_" "_tItemName_" "_$$$Text("following deployment since checked out by")_" "_tUserCheckedOut
						$$$OutputDeployLog(tInfo)
					}
				}
			} Else {
				/* 
					Item has been deleted  
				*/ 
			}
			Set tItemName = $O(pDeployDetails("SourceControl",tItemName))
		}
	} Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

ClassMethod SourceControlProductionSave(pProduction As %String, pAction As %String, ByRef pDeployDetails As %String) As %Status
{
	Set tSC = $$$OK
	Quit:'$IsObject($G(%SourceControl)) tSC
	Try {
		If pAction = "checkout"{
			Set tInfo = $$$Text("Checking out")_" "_pProduction_".CLS"_" "_$$$Text("for deployment. Invocation id")_": "_$G(pDeployDetails("InvocationId"))
			$$$OutputDeployLog(tInfo)
			Set tSC = %SourceControl.CheckOut(pProduction_".CLS",tInfo)
			Set pDeployDetails("SourceControl",pProduction_".CLS") = ""
		} ElseIf pAction = "compiled" {
			Set tSC = %SourceControl.OnAfterCompile(pProduction_".CLS")
		}
	} Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

/// Load code and compile code. 
/// Check out items if Source Control is enabled (Check in will be done at the end of deployment.
/// Compilation flags default to "ck-d" but can be changed setting the global ^Ens.Configuration("deploy","CompileFlags") the desired compilation flags.
ClassMethod LoadAndCompileCode(pFilename As %String, ByRef pDeployDetails, ByRef pErrors As %String, ByRef pLoadedList, ByRef pOBJectsToLoad, Output pFailureText) As %Status
{
	Set tCompileFlags = $G(^Ens.Configuration("deploy","CompileFlags"),"ck-d")
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(Ens.Deployment.Utils).SourceControlCheckOut(.pOBJectsToLoad,.pDeployDetails,.tItemsAlreadyCheckedOut)
		Quit:$$$ISERR(tSC) 
		If tItemsAlreadyCheckedOut {
			Set tInfo = $$$Text("Since starting the deployment item(s) in the deployment have been checked out by other(s). Stopping deployment.")
			Set tSC = $$$ERROR($$$EnsErrGeneral,tInfo)
			Set pFailureText = tInfo
			Quit
		}	
		Do $SYSTEM.OBJ.Load(pFilename,tCompileFlags,.pErrors,.pLoadedList,0,.pOBJectsToLoad)
		Set pFailureText = ""
		Set tError=$O(pErrors(""))
		While tError '= "" {
			Set tInfo = $$$Text("Error during import")_" "_pErrors(tError)
			$$$OutputDeployLog(tInfo)
			Set:(pFailureText = "") pFailureText = tInfo
			Set tError=$O(pErrors(tError))
		}
		Quit:(pFailureText'="")
		Set tItemName=$O(pOBJectsToLoad(""))
		While tItemName '= "" {
			Set tLastDot = $LENGTH(tItemName)+2-$FIND($REVERSE(tItemName),".")
			Set tItemNameRootAndDot = $E(tItemName,1,tLastDot)
			Set tItemExt = $E(tItemName,tLastDot+1,*)
			If ('$D(pLoadedList(tItemNameRootAndDot_$ZCVT(tItemExt,"U")))&&'$D(pLoadedList(tItemNameRootAndDot_$ZCVT(tItemExt,"L")))) {
				Set tInfo = $$$Text("Failed to import")_" "_tItemName
				$$$OutputDeployLog(tInfo)
				Set:(pFailureText = "") pFailureText = tInfo
				Quit
			} Else {
				Set tInfo = $$$Text("Successfully imported")_" "_tItemName
				$$$OutputDeployLog(tInfo)
			}
			Set tItemName=$O(pOBJectsToLoad(tItemName))
		}
		/* Now we look for any new items loaded that need now to be marked as checked out if have source control*/
		Kill tSourceControlToAdd
		Set tItemName = $O(pDeployDetails("SourceControl",""))
		While tItemName '= "" {
			Set:$G(pDeployDetails("SourceControl",tItemName,"ToBeAdded"),0) tSourceControlToAdd(tItemName)=""
			Set tItemName = $O(pDeployDetails("SourceControl",tItemName))
		}
		Set:($D(tSourceControlToAdd)) tSC = ##class(Ens.Deployment.Utils).SourceControlCheckOut(.tSourceControlToAdd,.pDeployDetails,.tItemsAlreadyCheckedOut)
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod getProjectItemList(pProjectName As %String, ByRef pContentsList As %String) As %Status [ Internal ]
{
	#dim tName, tType, tItemName As %String
	#dim tSC As %Status = $$$OK
	#dim tEx As %Exception.AbstractException
	Try {
		Set tResultSet = ##class(%Library.ResultSet).%New("%Studio.Project:ProjectItemsList")
		Set tSC = tResultSet.Execute(pProjectName)
		Quit:'tSC
		While tResultSet.Next() {
			Set tName = tResultSet.Get("Name")
			Set tType = tResultSet.Get("Type")
			If tType = "RUL" {
				Set tItemName = ##class(Ens.Projection.Rule).ResolveRuleAlias(tName)
				#;Ought not to be extension .RUL but check
				If tItemName = "" && ($Piece(tName,".",*)="RUL") {
					Set tItemName = ##class(Ens.Projection.Rule).ResolveRuleAlias($Piece(tName,".",1,*-1))
				}
				If tItemName '= "" Set tName = tItemName
				Set tType = "CLS"
			}
			If ((tType '= "MAC") && ($P($ZCVT(tName,"U"),".",$L(tName,"."))'=$ZCVT(tType,"U"))) {
				Set tName = tName_"."_tType
			} 
			#; %Studio.Project:ProjectItemsList by default expands PKG and including in list prevents export.
			If tType'="PKG" Set pContentsList(tName)=""
		}
	} Catch tEx {
		Set tSC = tEx.AsStatus()
	}
	Quit tSC
}

}
