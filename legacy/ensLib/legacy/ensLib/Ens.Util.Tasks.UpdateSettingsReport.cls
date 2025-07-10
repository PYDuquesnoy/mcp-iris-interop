/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This task is used to update a settings report.
/// For a given setting the task can be run in only one namespace.
/// 
Class Ens.Util.Tasks.UpdateSettingsReport Extends %SYS.Task.Definition
{

/// Default Localization Domain
Parameter DOMAIN = "Ensemble";

Parameter TaskName = "Interoperability Productions Settings Report";

Property iSettingReportClass As %String(DISPLAYLIST = ",Port Settings", MAXLEN = 255, VALUELIST = ",Ens.Setting.Report.Port") [ InitialExpression = "Ens.Setting.Report.Port" ];

/// Search all productions in all namespaces in this instance
/// Default is true
Property iiAllNamespaces As %Boolean [ InitialExpression = 1 ];

/// If not AllNamespaces then limit to this namespace
Property iiiSpecificNamespace As %String(MAXLEN = 255);

/// If true look for enterprise clients defined in this namespace
/// Default is off
Property ivIncludeExternalClients As %Boolean [ InitialExpression = 0 ];

/// If this is set then search is limited to this client
Property vSpecificExternalClientRegistryID As %String(MAXLEN = 254);

/// Override path for REST call to Enterprise client.
/// Default is /api/docdb/v1/<namespace>/find/<docdbname>
Property viExternalClientRESTPath As %String;

/// Log REST call errors to Enterprise Clients
/// Default is off
Property viiLogExternalCallErrors As %Boolean [ InitialExpression = 0 ];

/// Whether to call OnFinish() after saving results.
/// Default is true and OnFinish() will be called after saving.
Property viiiPostSaveProcessing As %Boolean [ InitialExpression = 1 ];

Method OnTask() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tReporter As Ens.Setting.Reporter = ##class(Ens.Setting.Reporter).%New()

	Try {

		Set tReporter.SettingReportClass = ..iSettingReportClass

		If 'tReporter.validSettingReportClass(.tSC) Quit

		Set tReporter.AllNamespaces = ..iiAllNamespaces

		Set tReporter.SpecificNamespace = ..iiiSpecificNamespace

		Set tReporter.IncludeExternalClients = ..ivIncludeExternalClients

		Set tReporter.ExternalClientRegistryID = ..vSpecificExternalClientRegistryID

		Set tReporter.ExternalClientRESTPath = ..viExternalClientRESTPath

		Set tReporter.LogExternalCallErrors = ..viiLogExternalCallErrors

		Set tReporter.CallonFinishSave = ..viiiPostSaveProcessing

		Set tSC =tReporter.SearchSettings()

		If $$$ISOK(tSC) Set tSC = tReporter.SaveSearchResults()

	} Catch e {

		Set tSC = e.AsStatus()

	}

	Quit tSC
}

}
