/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syInterop

/// This is the application class for the ZEN application.
Class EnsPortal.Application Extends (%CSP.Portal.Application, EnsPortal.Util.PageLinks) [ System = 4 ]
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "Interoperability Management Portal";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE = "%CSP.Portal.Home.zen";

/// Domain used for localization.
Parameter DOMAIN = "Ensemble";

/// This Style block contains application-wide CSS style definitions.
XData Style
{
<style type="text/css">

.fieldBoxIndent {
	background: #D7DBDD;
	width: 100%;
	overflow: auto;
}

/* used by side search menupane */
.hrline {
	background: #C6930A;
	height:4px;
}

.expandoNode {
	margin-top: 10px;
	padding-bottom: 10px;
	border-top: 1px solid #D0D0D0;
}

.expandoNode a {
	font-size: 10pt;
	font-weight: bold;
	color: #606060;
	border: none;
	text-decoration: none;
}

/* @doc="Mouse over expando caption." */
.expandoNode a:hover {
	color: #404040;
	background: #FFEEAA;
}

</style>
}

/// Provide finder contents for the Ensemble pages. Called from %CSP.Portal.Home.
ClassMethod GetEnsembleArray(Output pData) As %Status
{
	If '..CheckPrivileges() {
		Quit $$$OK
	}
	Set tIsMessageBank = $data(^Ens.MsgBankSvr)
	Set tHasEnterpriseSystems = $data(^Ens.Enterprise.MonitorClientD)\10
	//Set pMetaData = $LB("name","title","link","disabled","icon","description","resource","customResource","tags")
	Set tIndex=1
	Set pData(tIndex) =   $LB($$$Text("Configure"),,,,																																				..Link("portal/square_48.gif"))
	Set pData(tIndex,1) = $LB($$$Text("Production"),,              			..Link("EnsPortal.ProductionConfig.zen"),,        																		..Link("portal/enttity_relationship_model_48.gif"), $$$Text("View, Edit, Start or Stop a Production."),,,                         	$$$Text("Interoperability,Start,Production,Stop,Configure,Config,Monitor"))
	Set pData(tIndex,2) = $LB($$$Text("Production EXtensions Components"),,	..Link("EnsPortal.PEXComponents.zen"),,																					..Link("portal/list_48.gif"),						$$$Text("View, Update, or Register Production Extensions Components."),,,		$$$Text("Interoperability,PEX,Production,Production Extensions"))
	Set pData(tIndex,3) = $LB($$$Text("Business Partners"),,       			..Link("EnsPortal.BusinessPartners.zen"),,        																		..Link("portal/alliance_48.gif"),                   $$$Text("Create, View or Edit Business Partners."),,,                         	$$$Text("Interoperability"))
	Set pData(tIndex,4) = $LB($$$Text("Credentials"),,             			..Link("EnsPortal.Credentials.zen"),,             																		..Link("portal/security_48.gif"),                   $$$Text("Create, View or Edit Credentials."),,,                               	$$$Text("Interoperability"))
	Set pData(tIndex,5) = $LB($$$Text("Schedule Specs"),,          			..Link("EnsPortal.ScheduleEditor.zen"),,          																		..Link("portal/calendar_48.gif"),                   $$$Text("Create, View, or Edit Schedule Spec."),,,                            	$$$Text("Interoperability,Time"))
	Set pData(tIndex,6) = $LB($$$Text("Data Lookup Tables"),,      			..Link("EnsPortal.LookupSettings.zen"),,          																		..Link("portal/enttity_relationship_model_48.gif"), $$$Text("Create, View or Edit Lookup Table Settings."),,,                     	$$$Text("Interoperability,Translate"))
	Set pData(tIndex,7) = $LB($$$Text("System Default Settings"),, 			..Link("EnsPortal.DefaultSettings.zen"),,         																		..Link("portal/web_development_48.gif"),            $$$Text("Create, View, or Edit System-side Configuration Default values."),,, 	$$$Text("Interoperability,Config"))
	Set pData(tIndex,8) = $LB($$$Text("Purge Data Settings"),,	   			..Link("EnsPortal.PurgeSettings.zen"),,																					..Link("portal/web_development_48.gif"),			$$$Text("Modify default Purge Data settings."),,,							  	$$$Text("Interoperability,Purge,Configure,Default,Settings"))
	Set pData(tIndex,9) = $LB($$$Text("Enterprise Systems"),,      			..Link("Ens.Enterprise.Portal.SystemList.zen"),,  																		..Link("portal/comparison_chart_48.gif"),           $$$Text("View a List of Client Systems."),,,                                  	$$$Text("Interoperability,MsgBank,Message,Bank"))
	Set pData(tIndex,10) = $LB($$$Text("Public-Service Registry"),, 			..Link("EnsPortal.ServiceRegistry.Public.zen"),		'##class(Ens.ServiceRegistry.Public.API).UserIsRegistryManager(),  	..Link("portal/cluster_48.gif"),                    $$$Text("Create, View, or Edit Service Registry Entries."),,,                 	$$$Text("Interoperability"))
	Set pData(tIndex,11) = $LB($$$Text("External-Service Registry"),,		..Link("EnsPortal.ServiceRegistry.External.zen"),,																		..Link("portal/cluster_48.gif"),                   	$$$Text("Create, View, or Edit Service Registry Entries."),,,                 	$$$Text("Interoperability"))
	If ('tIsMessageBank) {
		Set pData(tIndex,12) = $LB($$$Text("Message Bank Link"),,   		..Link("EnsPortal.FindMsgBank.zen"),,             ..Link("portal/web_mail_48.gif"),				     $$$Text("Configure the Link to the Enterprise Message Bank"),,,               $$$Text("Interoperability,MsgBank,Message,Bank"))
	}
	Set tRuleEditorLink = ..GetRuleEditorURL(0)
	Set tIndex=tIndex+1
	Set tViewIndex = 0
	Set pData(tIndex) = $LB($$$Text("Build"),,,, ..Link("portal/design_team_48.gif"))
	Set pData(tIndex,$i(tViewIndex)) = $LB($$$Text("Business Processes"),,   ..Link("EnsPortal.BPLEditor.zen"),,            				..Link("portal/enttity_relationship_model_48.gif"), $$$Text("Create, View, or Edit Business Processes."),,,     $$$Text("Interoperability,BPL"))
	Set pData(tIndex,$i(tViewIndex)) = $LB($$$Text("Data Transformations"),, ..Link("EnsPortal.DTLEditor.zen"),,            				..Link("portal/merge_cells_48.gif"),                $$$Text("Create, View, or Edit Data Transformations"),,,    $$$Text("Interoperability,DTL"))
	If ##class(%Dictionary.ClassDefinition).%ExistsId("HS.InteropTools.HL7.GenerateDTL.UI.List") {
		Set pData(tIndex,$i(tViewIndex)) = $LB($$$Text("Generate DTL"),, 		 ..Link("HS.InteropTools.HL7.GenerateDTL.UI.List.zen"),,	..Link("portal/merge_cells_48.gif"),                $$$Text("Generate Data Transformations"),,,    				$$$Text("Interoperability,DTL"))
	}
	Set pData(tIndex,$i(tViewIndex)) = $LB($$$Text("Business Rules"),,       ..Link(tRuleEditorLink),,										..Link("portal/script_48.gif"),                     $$$Text("Create, View, or Edit Business Rules."),,,         $$$Text("Interoperability"))
	Set pData(tIndex,$i(tViewIndex)) = $LB($$$Text("Record Maps"),,          ..Link("EnsPortal.RecordMapper.zen"),,         				..Link("portal/eye_chart_48.gif"),                  $$$Text("View or Edit File Format Record Maps."),,,         $$$Text("Interoperability,File,Record,ETL,RecordMaps"))
	Set pData(tIndex,$i(tViewIndex)) = $LB($$$Text("CSV Record Wizard"),,    ..Link("EnsPortal.CSVRecordWizard.zen"),,      				..Link("deepsee/insert_table_48.png"),              $$$Text("Create Record Maps from delimited files."),,,      $$$Text("Interoperability,File,Record,ETL,CSV,RecordMaps"))
	Set pData(tIndex,$i(tViewIndex)) = $LB($$$Text("Complex Record Maps"),,  ..Link("EnsPortal.ComplexRecordMapper.zen"),,  				..Link("portal/eye_chart_48.gif"),                  $$$Text("View or Edit Complex Batch Maps."),,,              $$$Text("Interoperability,File,Record,ETL,RecordMaps,Batch,ComplexBatch,ComplexMaps"))
	Set tIndex=tIndex+1
	Set pData(tIndex) = $LB($$$Text("View"),,,, ..Link("portal/zoom_48.gif"))
	Set tViewIndex = 0
	If tIsMessageBank {
		Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Banked Messages"),,     ..Link("Ens.Enterprise.Portal.MsgBankViewer.zen"),,..Link("portal/mail_search_48.gif"),               $$$Text("View or Search Banked Messages."),,,                                 $$$Text("Interoperability,MsgBank,Message,Bank"))
		Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Banked Events"),,       ..Link("Ens.Enterprise.Portal.MsgBankEventLog.zen"),,..Link("portal/list_search_48.gif"),             $$$Text("View or Search Banked Events."),,,                                   $$$Text("Interoperability,MsgBank,Message,Bank"))
	}
	If tHasEnterpriseSystems {
		Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Enterprise Messages"),,   ..Link("Ens.Enterprise.Portal.EnterpriseSearch.zen"),,..Link("portal/mail_search_48.gif"),            $$$Text("View or Search Messages on Enterprise Clients."),,,                  $$$Text("Interoperability"))
	}
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Messages"),,                ..Link("EnsPortal.MessageViewer.zen"),,           ..Link("portal/mail_search_48.gif"),                $$$Text("View or Search Messages."),,,                                        $$$Text("Interoperability"))
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Suspended Messages"),,      ..Link("EnsPortal.SuspendedMsg.zen"),,            ..Link("portal/mail_clock_48.gif"),                 $$$Text("Manage Suspended Messages."),,,                                      $$$Text("Interoperability"))
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Event Log"),,               ..Link("EnsPortal.EventLog.zen"),,                ..Link("portal/list_search_48.gif"),                $$$Text("View or Search the Event Log."),,,                                   $$$Text("Interoperability"))
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Business Rule Log"),,       ..Link("EnsPortal.RuleLog.zen"),,                 ..Link("portal/list_search_48.gif"),                $$$Text("View or Search the Rule Log."),,,                                    $$$Text("Interoperability,Rules"))
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Business Process Log"),,    ..Link("EnsPortal.BPInstances.zen"),,             ..Link("portal/list_search_48.gif"),                $$$Text("View or Search Business Process instances."),,,                      $$$Text("Interoperability,BP"))
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Managed Alerts"),,          ..Link("EnsPortal.ManagedAlertViewer.zen"),,      ..Link("portal/list_search_48.gif"),           	    $$$Text("View or Search for Managed Alerts."),,,                              $$$Text("Interoperability,Managed,Alert"))
	If 'tIsMessageBank {
		Set tBankLink = ##class(EnsPortal.FindMsgBank).GetBankLink()
		If tBankLink = "" {
			Set tBankLink = "EnsPortal.FindMsgBank.zen"
			Set tBankDesc = $$$Text("Link to Message Bank not configured.")_" "_$$$Text("Configure the Link to the Enterprise Message Bank")
			Set tBankTitle = $$$Text("Configure the Link to the Enterprise Message Bank")
		}
		Else {
			Set tBankDesc = $$$Text("Go to the Enterprise Message Bank / Monitor portal.")
			Set tBankTitle = ""
		}
		Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Enterprise Message Bank"),tBankTitle,..Link(tBankLink),,       ..Link("portal/web_mail_48.gif"),                   tBankDesc,,,                                                                  $$$Text("Interoperability,MsgBank,Message,Bank"))
	}
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Interface Maps"),,		  ..Link("EnsPortal.InterfaceMaps.zen"),,			..Link("deepsee/ds2_map_44.png"),					$$$Text("View or Search Production Routes"),,,								  $$$Text("Interoperability,Production,Search"))
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Interface References"),,	..Link("EnsPortal.InterfaceReferences.zen"),,		..Link("deepsee/ds2_magnify_44.png"),				$$$Text("Search interface references."),,,									$$$Text("Interoperability,BPL,Rules,DTL,Transforms,Schemas,HL7,LUT,Lookup,Tables,Utility,Functions,Search"))
	Set pData(tIndex,$I(tViewIndex)) = $LB($$$Text("Port Authority Report"),,	..Link("EnsPortal.Setting.Report.ProductionPorts.zen"),'$SYSTEM.DocDB.Exists("IRISInteroperabilityPorts"),		..Link("deepsee/ds2_magnify_44.png"),				$$$Text("Port Authority Report."),,,									$$$Text("Interoperability,PortSettingReport,Utility,Search"))
	Set tIndex=tIndex+1
	Set pData(tIndex) = $LB($$$Text("List"),,,, ..Link("portal/list_search_48.gif"))
	Set pData(tIndex,1) = $LB($$$Text("Business Processes"),,      ..Link("EnsPortal.BusinessProcesses.zen"),,       ..Link("portal/list_search_48.gif"),                $$$Text("View a List of Business Processes."),,,                              $$$Text("Interoperability,BPL,"))
	Set pData(tIndex,2) = $LB($$$Text("Data Transformations"),,    ..Link("EnsPortal.DataTransformations.zen"),,     ..Link("portal/list_search_48.gif"),                $$$Text("View a List of Data Transformations."),,,                            $$$Text("Interoperability,DTL,Transforms"))
	Set pData(tIndex,3) = $LB($$$Text("Business Rules"),,          ..Link("EnsPortal.Rules.zen"),,                   ..Link("portal/list_search_48.gif"),                $$$Text("View a List of Business and Routing Rules."),,,                      $$$Text("Interoperability"))
	Set pData(tIndex,4) = $LB($$$Text("Record Maps"),,             ..Link("EnsPortal.RecordMaps.zen"),,              ..Link("portal/list_search_48.gif"),                $$$Text("View a List of Record Maps."),,,                                     $$$Text("Interoperability,RecordMaps"))
	Set pData(tIndex,5) = $LB($$$Text("Productions"),,             ..Link("EnsPortal.Productions.zen"),,             ..Link("portal/list_search_48.gif"),                $$$Text("Manage other productions."),,,                                       $$$Text("Interoperability"))
	Set tIndex=tIndex+1
	Set pData(tIndex) = $LB($$$Text("Monitor"),,,, ..Link("portal/gauge_48.gif"))
	Set pData(tIndex,1) = $LB($$$Text("System Monitor"),,          ..Link("/csp/sys/%25CSP.UI.Portal.EnsembleMonitor.zen"),, ..Link("portal/network_monitor_48.gif"),    $$$FormatText($$$Text("View the %1 system monitor."),$$$PRODUCT2))
	Set pData(tIndex,2) = $LB($$$Text("Production Monitor"),,      ..Link("EnsPortal.ProductionMonitor.zen"),,       ..Link("portal/architecture_info_48.gif"),    		 $$$Text("View the production monitor."))
	Set pData(tIndex,3) = $LB($$$Text("Queues"),,                  ..Link("EnsPortal.Queues.zen"),,                  ..Link("portal/junk_email_filter_48.gif"),          $$$FormatText($$$Text("View %1 queues."),$$$PRODUCT2))
	Set pData(tIndex,4) = $LB($$$Text("Jobs"),,                    ..Link("EnsPortal.Jobs.zen"),,                    ..Link("portal/osi_model_48.gif"),                  $$$FormatText($$$Text("View %1 jobs."),$$$PRODUCT2))
	Set pData(tIndex,5) = $LB($$$Text("Alerts"),,       		   ..Link("EnsPortal.ManagedAlerts.zen"),,           ..Link("portal/comparison_chart_48.gif"),           $$$Text("View details about open Managed Alerts."),,,                            $$$Text("Interoperability,Managed,Alert"))
	Set pData(tIndex,6) = $LB($$$Text("Activity"),, 			   ..Link("EnsPortal.ActivityVolumeAndDuration.zen"),, ..Link("portal/comparison_chart_48.gif"),    $$$Text("View a dashboard containing activity summary numbers and charts."),,, $$$Text("Interoperability,Monitor,Dashboard,Activity,Volume,Duration,Summary,Chart"))
	If tHasEnterpriseSystems {
		Set pData(tIndex,7) = $LB($$$Text("Enterprise Monitor"),,  ..Link("Ens.Enterprise.Portal.MonitorStatus.zen"),,..Link("portal/architecture_info_48.gif"),         $$$Text("View the Enterprise Monitor."),,,                                    $$$Text("Interoperability,MsgBank,Message,Bank"))
	}
	Set tIndex=tIndex+1
	Set pData(tIndex) = $LB($$$Text("Manage"),,,, ..Link("portal/binary_field_48.gif"))
	Set pData(tIndex,1) = $LB($$$Text("Purge Management Data"),,   ..Link("EnsPortal.PurgeAll.zen"),,                ..Link("portal/binary_field_remove_48.gif"),        $$$Text("Purge Messages, Logs and Monitor records."),,,                       $$$Text("Interoperability"))
	Set pData(tIndex,2) = $LB($$$Text("Auto-Start Production"),,   ..Link("EnsPortal.AutoStartProduction.zen"),,     ..Link("portal/cache_config_48.gif"),               $$$Text("Select a Production to start automatically."),,,                     $$$Text("Interoperability,AutoStart"))
	Set pData(tIndex,3) = $LB($$$Text("Local Archive Manager"),,   ..Link("EnsPortal.ArchiveManager.zen"),,          ..Link("portal/enttity_relationship_model_48.gif"), $$$Text("Define or Run Local Archives."),,,                                   $$$Text("Interoperability"))
	Set pData(tIndex,4) = $LB($$$Text("Workflow"),,,, ..Link("portal/clients_48.gif"))
	Set pData(tIndex,4,1) = $LB($$$Text("Workflow Roles"),,        ..Link("EnsPortal.WFRoles.zen"),,                 ..Link("portal/role_48.gif"),                       $$$Text("Create, view or edit Workflow roles."),,,                            $$$Text("Interoperability"))
	Set pData(tIndex,4,2) = $LB($$$Text("Workflow Users"),,        ..Link("EnsPortal.WFUsers.zen"),,                 ..Link("portal/clients_48.gif"))
	Set pData(tIndex,4,3) = $LB($$$Text("Workflow Tasks"),,        ..Link("EnsPortal.WFTasklist.zen"),,              ..Link("portal/log_search_48.gif"),                 $$$Text("View or edit Workflow tasks."),,,                                    $$$Text("Interoperability"))
	Set pData(tIndex,4,4) = $LB($$$Text("Workflow Worklist"),,     ..Link("EnsPortal.WFWorklist.zen"),,              ..Link("portal/copy_search_48.gif"),                $$$Text("View or edit Workflow worklists."),,,                                $$$Text("Interoperability"))
	Set pData(tIndex,5) = $LB($$$Text("Publish & Subscribe"),,     ..Link("EnsPortal.PubSub.PageContainer.cls"),,    ..Link("portal/script_48.gif"),                     $$$Text("View or edit Subscriptions, Domains and Subscribers."),,,            $$$Text("Interoperability"))
	Set pData(tIndex,6) = $LB($$$Text("Deployment Changes"),,,'$system.Security.Check("%Ens_Deploy","USE"),..Link("portal/write_48.gif"))
	Set pData(tIndex,6,1) = $LB($$$Text("Deploy"),,                ..Link("EnsPortal.Deployment.DeployProductionChanges.zen"),,..Link("portal/write_48.gif"),           $$$Text("Deploy changes to a production."),,,                                 $$$Text("Interoperability"))
	Set pData(tIndex,6,2) = $LB($$$Text("History"),,               ..Link("EnsPortal.Deployment.DeploymentHistory.zen"),,..Link("portal/write_48.gif"),                 $$$Text("Deployment history."),,,                                             $$$Text("Interoperability"))
	Set pData(tIndex,7) = $LB($$$Text("Configuration"),,,, ..Link("portal/gear_48.gif"))
	Set pData(tIndex,7,1) = $LB($$$Text("Production Shutdown Groups"),,        ..Link("EnsPortal.ProductionShutdownGroup.zen"),,                 ..Link("portal/cache_config_48.gif"),                $$$Text("View or Edit Production Shutdown Groups."),,,  $$$Text("Interoperability"))
	Set pData(tIndex,7,2) = $LB($$$Text("Setting Report Application Configuration"),,        ..Link("EnsPortal.Setting.Report.Configuration.zen"),,                 ..Link("portal/cache_config_48.gif"),                $$$Text("View or Edit Configuration of Setting Report Application."),,,  $$$Text("Interoperability"))
	Set pData(tIndex,7,3) = $LB($$$Text("Interoperability Settings"),,        ..Link("EnsPortal.Configuration.Settings.zen"),,                 ..Link("portal/cache_config_48.gif"),                $$$Text("View or Edit Interoperability Configuration Settings."),,,  $$$Text("Interoperability"))
	Set tIndex=tIndex+1
	Set pData(tIndex) = $LB($$$Text("Interoperate"),,,, ..Link("portal/mime_48.gif"))
	#dim tSub = 0

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("X12") {
		Set tSub = tSub + 1
		Set pData(tIndex,tSub) = $LB($$$Text("ASC X12"),,,, ..Link("portal/mime_48.gif"))
		Set pData(tIndex,tSub,1) = $LB($$$Text("ASC X12 Schema Structures"),,    ..Link("EnsPortal.EDI.X12.SchemaMain.zen"),,     ..Link("portal/eye_chart_info_48.gif"),       $$$Text("View, import, export, and remove schemas"),,,           $$$Text("Interoperability,SEF,EDI"))
		Set pData(tIndex,tSub,2) = $LB($$$Text("ASC X12 Document Viewer"),,      ..Link("EnsPortal.EDIDocumentView.zen?NAME=X12 Document"),,           ..Link("portal/mail_search_48.gif"),          $$$Text("View and transform documents"),,,               $$$Text("Interoperability,EDI"))
	}

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("ASTM") {
		Set tSub = tSub + 1
		Set pData(tIndex,tSub) = $LB($$$Text("ASTM"),,,, ..Link("portal/mime_48.gif"))
		Set pData(tIndex,tSub,1) = $LB($$$Text("ASTM Schema Structures"),,       ..Link("EnsPortal.EDI.ASTM.SchemaMain.zen"),,               ..Link("portal/eye_chart_info_48.gif"),       $$$Text("View, import, export, and remove schemas"),,,   $$$Text("Interoperability,EDI"))
		Set pData(tIndex,tSub,2) = $LB($$$Text("ASTM Document Viewer"),,         ..Link("EnsPortal.EDIDocumentView.zen?NAME=ASTM Document"),,          ..Link("portal/mail_search_48.gif"),          $$$Text("View and transform documents"),,,               $$$Text("Interoperability,EDI"))
	}

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("DICOM") {
		Set tSub = tSub + 1
		Set pData(tIndex,tSub) = $LB($$$Text("DICOM"),,,, ..Link("portal/radiology_48.gif"))
		Set pData(tIndex,tSub,1) = $LB($$$Text("DICOM Settings"),,               ..Link("EnsPortal.DICOM.Settings.zen"),,                              ..Link("portal/radiology_config_48.gif"),     $$$Text("Create, view or edit DICOM associations"),,,    $$$Text("Interoperability,EDI"))
		Set pData(tIndex,tSub,2) = $LB($$$Text("DICOM Abstract Syntax"),,        ..Link("EnsPortal.DICOM.ASList.zen"),,                                ..Link("portal/radiology_info_48.gif"),       $$$Text("View DICOM abstract syntax"),,,                 $$$Text("Interoperability,EDI"))
		Set pData(tIndex,tSub,3) = $LB($$$Text("DICOM Dictionary"),,             ..Link("EnsPortal.DICOM.Dictionary.zen"),,                            ..Link("portal/radiology_info_48.gif"),       $$$Text("View DICOM dictionary"),,,                      $$$Text("Interoperability,EDI"))
	}

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("HL7") {
		Set tSub = tSub + 1
		Set pData(tIndex,tSub) = $LB($$$Text("HL7 v2.x"),,,,  ..Link("portal/eye_chart_48.gif"))
		Set pData(tIndex,tSub,1) = $LB($$$Text("HL7 v2.x Schema Structures"),,   ..Link("EnsPortal.HL7.SchemaMain.zen"),,                    ..Link("portal/eye_chart_info_48.gif"),       $$$Text("View, import, export, and remove schemas"),,,   $$$Text("Interoperability,EDI"))
		Set pData(tIndex,tSub,2) = $LB($$$Text("HL7 v2.x Message Viewer"),,      ..Link("EnsPortal.EDIDocumentView.zen?NAME=HL7 Message"),,            ..Link("portal/mail_search_48.gif"),          $$$Text("View and transform documents"),,,               $$$Text("Interoperability,EDI"))
	}

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("SEF") {
		Set tSub = tSub + 1
		Set pData(tIndex,tSub) = $LB($$$Text("UN/EDIFACT"),,,, ..Link("portal/mime_48.gif"))
		Set pData(tIndex,tSub,1) = $LB($$$Text("UN/EDIFACT Schema Structures"),, ..Link("EnsPortal.EDI.SEF.SchemaMain.zen?FAMILY=EDIFACT"),, ..Link("portal/mime_48.gif"),                 $$$Text("View, import, and remove schemas"),,,           $$$Text("Interoperability,SEF,EDI"))
		Set pData(tIndex,tSub,2) = $LB($$$Text("UN/EDIFACT Document Viewer"),,   ..Link("EnsPortal.EDIDocumentView.zen?NAME=EDIFACT Document"),,       ..Link("portal/mail_search_48.gif"),          $$$Text("View and transform documents"),,,               $$$Text("Interoperability,EDI"))
	}
	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("XML") {
		Set tSub = tSub + 1
		Set pData(tIndex,tSub) = $LB($$$Text("XML"),,,, ..Link("portal/mime_48.gif"))
		Set pData(tIndex,tSub,1) = $LB($$$Text("XML Schema Structures"),,        ..Link("EnsPortal.EDI.XML.SchemaMain.zen"),,                ..Link("portal/report_config_48.gif"),        $$$Text("View, import, and remove schemas"),,,   $$$Text("Interoperability,VDoc,Virtual,Document"))
		Set pData(tIndex,tSub,2) = $LB($$$Text("XML Document Viewer"),,          ..Link("EnsPortal.EDIDocumentView.zen?NAME=XML Document"),,           ..Link("portal/mail_search_48.gif"),          $$$Text("View and transform documents"),,,               $$$Text("Interoperability,VDoc,Virtual,Document"))
	}

	Set tIndex=tIndex+1
	Set pData(tIndex) = $LB($$$Text("Test"),,,,..Link("portal/software_development_48.gif"))
	Set pData(tIndex,1) = $LB($$$Text("Business Hosts"),,                 ..Link("EnsPortal.TestingService.zen"),,                              ..Link("portal/design_team_48.gif"),          $$$Text("Run the testing service for business processes or business operations"),,,     $$$Text("Interoperability"))
	Set pData(tIndex,2) = $LB($$$Text("Data Transformations"),,           ..Link("EnsPortal.DataTransformations.zen"),'$system.Security.Check("%Ens_DTLTest","USE"),..Link("portal/list_search_48.gif"), $$$Text("View a List of Data Transformations and select one for testing"),,, $$$Text("Interoperability"))

	// Add the ITK options if the ITK setup package is present
	If ##class(%Dictionary.PackageDefinition).%ExistsId("ITK.Setup") {
		Set tIndex=tIndex+1
		Set pData(tIndex) = $LB($$$Text("ITK Setup"),,,, ..Link("portal/gear_48.gif"))
		Set pData(tIndex,1) = $LB($$$Text("Service Definitions"),, ..Link("ITK.Setup.UI.EditServiceDefinitions.zen"),,         ..Link("portal/gear_48.gif"),            $$$Text("Create, View, or Edit ITK Service Definitions."),,, $$$Text("Interoperability,ITK,Services"))
		Set pData(tIndex,2) = $LB($$$Text("Registry Viewer"),, ..Link("ITK.Setup.UI.RegistryViewer.zen"),,         ..Link("portal/gear_48.gif"),            $$$Text("Setup the ITK Sender, Consumer and Subscription Rules Registries"),,, $$$Text("Interoperability,ITK,Registry"))
		Set pData(tIndex,3) = $LB($$$Text("Fault Codes"),, ..Link("ITK.Setup.UI.EditFaultCodes.zen"),,         ..Link("portal/gear_48.gif"),            $$$Text("Setup the ITK Fault Vocabularies and Fault Codes"),,, $$$Text("Interoperability,ITK,Fault,Vocabulary"))
		Set pData(tIndex,4) = $LB($$$Text("Fault Map"),, ..Link("ITK.Setup.UI.EditFaultMap.zen"),,         ..Link("portal/gear_48.gif"),            $$$Text("Setup the ITK Fault Code Map"),,, $$$Text("Interoperability,ITK,Fault,Map"))
	}

	If $d(^EnsLib.Hub) Set tSC = ##class(EnsLib.Hub.UI.Application).GetIMTArray(.tIndex, .pData)
	If $d(^%MPRL.Installed) set tSC = ##class(%MPRL.Utils.EnsPortal).addMenuItems(.tIndex,.pData)

	Quit $$$OK
}

/// Ensure the user has USE permissions on %Ens_Portal and
/// READ permissions on the default database for the current namespace.
ClassMethod CheckPrivileges() As %Boolean
{
	Set tPermitted = 1
	If '$system.Security.Check("%Ens_Portal","USE") {
		Set tPermitted = 0
	}
	Else {
		Do GetNSInfo^%SYS.NAMESPACE($namespace,.tInfo)
		Set tDBResource = $get(tInfo("Resource"))
		If (tDBResource '= "") && '$system.Security.Check(tDBResource,"READ") {
			Set tPermitted = 0
		}
	}
	Quit tPermitted
}

/// Overrides super class method to be able to set custom web application
/// if applicable in GetEnsembleArray().
/// Tranforms the link specified by <VAR>link</VAR> into a URL and returns it as a string.
/// <p>The URL may be encrypted.</p>
/// <p>The array, <VAR>query</VAR>, contains an optional set of name-value pairs 
/// which are added to the URL. For example 'Set query("name")="data"'</p>
/// <p>If the optional argument <var>addQ</var> is true, then a ? or &amp;,
/// as appropriate, is added to end of the URL</p>
ClassMethod Link(link As %String, ByRef query As %String, addQ As %Boolean = 0) As %String [ ServerOnly = 1 ]
{
	/* Use standard web application if HealthShare or HealthConnect product or not set custom portal URL */
	If (link["/csp/sys/")||(link[$$$InteropWebAppRoot)||($$$ISCPRODUCTCODE=$$$HealthShareProductKey)||($Get(^%SYS("Ensemble","InstalledNamespace",$Namespace))="") {

		Quit ##super(link,.query,addQ)

	}

	#dim tURL = ##class(%Library.EnsembleMgr).DetermineMgmtURLForNamespace($Namespace,0)

	Quit $$cspLink^%SYS.cspServer((tURL_link),.query,addQ)
}

}
