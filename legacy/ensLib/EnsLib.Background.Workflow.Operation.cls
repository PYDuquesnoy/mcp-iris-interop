/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Business Operation manages the delegation of workflow tasks to the Ensemble Workflow Engine for background work.
Class EnsLib.Background.Workflow.Operation Extends Ens.BusinessOperation [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter INVOCATION = "InProc";

/// Take a Task and give it to the Workflow Engine for distribution.
/// The role is taken from the optional %Command property.
/// If the %Command property is empty the role name is taken from the config name.
Method OnMessage(pTask As EnsLib.Workflow.TaskRequest, Output pResponse As EnsLib.Workflow.TaskResponse) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		// role is taken from optional %Command and if empty use config name
		#dim tRoleName = pTask.%Command
		If tRoleName = "" Set tRoleName = ..%ConfigName

		Set tSC = ..createRole(tRoleName)
		If $$$ISERR(tSC) Quit

		// We will send an answer later
		#dim tToken
		Set tSC = ..DeferResponse(.tToken)
		If $$$ISERR(tSC) Quit

		// Send task to Workflow Engine for distribution
		Set tSC = ##class(EnsLib.Workflow.Engine).%DistributeTask(tRoleName, pTask, tToken)
		If $$$ISERR(tSC) Quit

	} Catch ex {

		Set tSC=$$$EnsSystemError

	}

	Quit tSC
}

Method createRole(pRoleName As %String = "") As %Status
{
	#dim tSC = $$$OK
	If '##class(EnsLib.Workflow.RoleDefinition).%ExistsId(pRoleName) {
		Set tSC = ##class(EnsLib.Workflow.RoleDefinition).CreateRole(pRoleName)
	}
	Quit $$$OK
}

}
