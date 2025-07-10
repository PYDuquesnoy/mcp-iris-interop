/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Business Operation manages the delegation of workflow tasks to the Workflow Engine.
Class EnsLib.Workflow.Operation Extends Ens.BusinessOperation [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter INVOCATION = "Queue";

Parameter SETTINGS = "AutoCreateRole:Basic";

/// If true, then this operation, when it starts, will automatically 
/// create a corresponding Workflow Role definition if one does 
/// not currently exist.
Property AutoCreateRole As %Boolean [ InitialExpression = 0 ];

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.Workflow.TaskRequest"> 
		<Method>TaskHandler</Method>
	</MapItem>
</MapItems>
}

/// Take a Task and give it to the Workflow Engine for distribution.
/// The role is assumed to be the same as the configuration name of this operation.
Method TaskHandler(pTask As EnsLib.Workflow.TaskRequest, Output pResponse As EnsLib.Workflow.TaskResponse) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		// role is our Config Name
		Set tRoleName = ..%ConfigName
		
		// We will send an answer later
		Set tSC = ..DeferResponse(.tToken)
		If $$$ISERR(tSC) Quit
		
		// Send task to Workflow Engine for distribution
		Set tSC = ##class(Engine).%DistributeTask(tRoleName, pTask, tToken)
		If $$$ISERR(tSC) {
			Quit
		}
	} While (0)

Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method OnInit() As %Status
{
	// role is our Config Name
	Set tRoleName = ..%ConfigName
	
	// test for auto-create of Role definition
	If (..AutoCreateRole) {
		If '##class(RoleDefinition).%ExistsId(tRoleName) {
			Set tSC = ##class(RoleDefinition).CreateRole(tRoleName)
			If $$$ISERR(tSC) {
				// log error
				$$$LOGERROR("Unable to auto-create role definition")
			}
		}
	}

	Quit $$$OK
}

}
