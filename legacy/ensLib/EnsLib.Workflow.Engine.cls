/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsWorkflow)

/// Provides the core APIs for the Ensemble Workflow system.
Class EnsLib.Workflow.Engine Extends %RegisteredObject [ ClassType = "", CompileAfter = (EnsLib.Workflow.RoleMembership, EnsLib.Workflow.Worklist), ProcedureBlock, System = 4 ]
{

/// This Workflow API method assigns a Task to a specific User.
ClassMethod AssignTask(pTask As EnsLib.Workflow.TaskResponse, pUser As %String, Output pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pCount = 0

	Do {
		If ('##class(EnsLib.Workflow.UserDefinition).%ExistsId(pUser)) {
			// invalid user name
			Set tSC = $$$EnsError($$$EnsWfErrUserUndefined, pUser)
			Quit
		}
		// make sure there is a worklist item for this task
		Set tSC = ..SendTask(pTask, pUser)
		If $$$ISERR(tSC) Quit
		
		// change state of this task and save it
		Set pTask.%Status = $$$WfTaskAssigned
		Set pTask.%TaskStatus.AssignedTo = pUser
		Set tSC = pTask.%Save()
		If $$$ISERR(tSC) Quit

		Set pCount = 1

		Set tTaskId = pTask.%Id()
		// delete all the other worklist items
		&sql(DELETE FROM Worklist 
				WHERE (Task = :tTaskId) AND (UserName <> :pUser) )
		If (SQLCODE < 0) Set tSC = $$$ERROR($$$EnsErrGeneral,"While assigning a task, delete from Worklist failed with SQLCODE "_SQLCODE)
	} While (0)
	
	Quit tSC
}

/// This Workflow API method unassign a Task associated with specific User.
/// Tests if <var>pUser</var> owns the task (if provided).
ClassMethod UnassignTask(pTask As EnsLib.Workflow.TaskResponse, pUser As %String = "") As %Status
{
	Set tSC = $$$OK
	Do {
		If (pUser '= "") {
			If ('##class(EnsLib.Workflow.UserDefinition).%ExistsId(pUser)) {
				// invalid user name
				Set tSC = $$$EnsError($$$EnsWfErrUserUndefined, pUser)
				Quit
			}
			If (pTask.%TaskStatus.AssignedTo '= pUser) {
				Set tSC = $$$EnsError($$$EnsWfErrTaskAssignedToOther, pUser, pTask.%TaskStatus.AssignedTo)
				Quit
			}
		}
		Set tOld = pTask.%TaskStatus.AssignedTo
		Set tTaskId = pTask.%Id()
		
		// change state of this task and save it
		Set pTask.%TaskStatus.AssignedTo = ""
		Set pTask.%Status = $$$WfTaskUnassigned
		Set tSC = pTask.%Save()
		If $$$ISERR(tSC) Quit

		// delete old worklist items
		// assume caller will create new ones
		&sql(DELETE FROM Worklist 
				WHERE (Task = :tTaskId) AND (UserName = :tOld) )
		If (SQLCODE < 0) Set tSC = $$$ERROR($$$EnsErrGeneral,"While assigning a task, delete from Worklist failed with SQLCODE "_SQLCODE)
	} While (0)
	
	Quit tSC
}

/// This Workflow API method sends (but does not assign) a Task to a specific User.
/// <var>pUser</var> is the name of the user.
/// On return, <var>pCount</var> is number of users task was sent to.
ClassMethod SendTask(pTask As EnsLib.Workflow.TaskResponse, pUser As %String, Output pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	
	Set pCount = 0

	Do {
		// see if worklist item already exists for user
		If (..ItemExistsForTask(pTask.%Id(),pUser)) {
			Quit
		}

		// create worklist item for this user
		Set tItem = ##class(EnsLib.Workflow.Worklist).%New()
		Set tItem.Task = pTask
		Do tItem.UserSetObjectId(pUser)
		Set tItem.Role = pTask.%TaskStatus.Role
		Set tSC = tItem.%Save()
		If $$$ISERR(tSC) Quit
		
		Set pCount = pCount + 1
	} While(0)

	Quit tSC
}

/// This Workflow API method sends (but does not assign) a Task to all Users within the current Role.
/// On return, <var>pCount</var> is number of users task was sent to.
ClassMethod SendTaskToAll(pTask As EnsLib.Workflow.TaskResponse, Output pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pCount = 0
	
	Do {
		// get set of all users for this role
		Set tUserSet = pTask.%TaskStatus.Role.GetUserSet()
		If ('$IsObject(tUserSet)) {
			Set tSC = $$$EnsError($$$EnsWfErrNoUserSet)
			Quit
		}

		// now send task to each of the users	
		While (tUserSet.Next()) {
			Set tUser = $G(tUserSet.Data("UserName"))
			Set tSC = ..SendTask(pTask,tUser,.tCount)
			If $$$ISERR(tSC) Quit
			
			Set pCount = pCount + tCount
		}

	} While(0)
	
	Quit tSC
}

/// This Workflow API method sends (but does not assign) a Task to all Users within the current Role
/// with title <var>pTitle</var>.
/// On return, <var>pCount</var> is number of users task was sent to.
ClassMethod SendTaskToTitle(pTask As EnsLib.Workflow.TaskResponse, pTitle As %String = "", Output pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pCount = 0
	
	Do {
		// get set of all users for this role with given title
		Set tUserSet = pTask.%TaskStatus.Role.GetUserSet(pTitle)
		If ('$IsObject(tUserSet)) {
			Set tSC = $$$EnsError($$$EnsWfErrNoUserSet)
			Quit
		}

		// now send task to each of the users	
		While (tUserSet.Next()) {
			Set tUser = $G(tUserSet.Data("UserName"))
			Set tSC = ..SendTask(pTask,tUser,.tCount)
			If $$$ISERR(tSC) Quit
			
			Set pCount = pCount + tCount
		}

	} While(0)
	
	Quit tSC
}

/// This Workflow API method sends (but does not assign) a Task to <var>pNum</var> top ranked
/// Users within the current Role.
/// On return, <var>pCount</var> is number of users task was sent to.
ClassMethod SendTaskToTop(pTask As EnsLib.Workflow.TaskResponse, pNum As %Integer = 1, Output pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pCount = 0
	
	Do {
		// get set of all active users for this role
		Set tUserSet = pTask.%TaskStatus.Role.GetUserSet()
		If ('$IsObject(tUserSet)) {
			Set tSC = $$$EnsError($$$EnsWfErrNoUserSet)
			Quit
		}

		// now send task to the top n users
		While ((pCount < pNum) && tUserSet.Next()) {
			Set tUser = $G(tUserSet.Data("UserName"))
			Set tSC = ..SendTask(pTask, tUser, .tCount)
			If $$$ISERR(tSC) Quit

			Set pCount = pCount + tCount
		}

	} While(0)
	
	Quit tSC
}

/// This Workflow API method marks a task as complete and 
/// returns a response to the original requestor.
ClassMethod CompleteTask(pTask As EnsLib.Workflow.TaskResponse, pAction As %String = "") As %Status
{
	Set tSC = $$$OK
	
	Do {
		// fill in final response properties
		Set tStatus = pTask.%TaskStatus
		Set pTask.%UserName = tStatus.AssignedTo
		Set pTask.%RoleName = tStatus.Role.Name
		
		// get membership-related info
		If ((pTask.%UserName '= "") && (pTask.%RoleName '= "")) {
			Set tMbr = ##class(RoleMembership).%OpenId(pTask.%RoleName _ "||" _ pTask.%UserName)
			If $IsObject(tMbr) {
				Set pTask.%UserTitle = tMbr.Title
				Set pTask.%UserRanking = tMbr.Ranking
			}
		}

		// if no action, cancel
		If (pAction = "") {
			Set pTask.%Action = $$$WfTaskCancelled
			Set pTask.%Status = $$$WfTaskCancelled
		}
		Else {
			Set pTask.%Action = pAction
			Set pTask.%Status = $$$WfTaskCompleted
		}

		Set tStatus.IsComplete = 1
		Set tStatus.TimeCompleted = $$$timeUTC
		Set tTaskId = pTask.%Id()

		// delete the worklist items associated with this task
		&sql(DELETE FROM Worklist WHERE Task = :tTaskId)
		If (SQLCODE < 0) Set tSC = $$$ERROR($$$EnsErrGeneral,"While assigning a task, delete from Worklist failed with SQLCODE "_SQLCODE)

		// return task as response to caller
		Set tSC = ##class(Ens.Host).SendDeferredResponse(tStatus.ResponseToken, pTask)
		If $$$ISERR(tSC) Quit

	} While(0)

	Quit tSC
}

/// Find the name of the highest-ranked, active user within the given role that has the least
/// number of tasks (for any role) assigned to them.
/// On return <var>pCount</var> has current number of tasks for this user.
ClassMethod FindLeastBusyUser(pRoleName As %String, Output pUserName As %String, Output pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pUserName = ""

	&sql(DECLARE sql1 CURSOR FOR

	SELECT U.Name As UserName, M.Ranking As Ranking, U.IsActive As IsActive,

 	(SELECT COUNT(*) FROM EnsLib_Workflow.TaskResponse Task WHERE ((M.UserName = Task.TaskStatus_AssignedTo) AND (Task.TaskStatus_IsComplete=0))) As Tasks
	INTO :tName,:tRanking,:tIsActive,:tTasks

 	FROM EnsLib_Workflow.UserDefinition U 
 	INNER JOIN EnsLib_Workflow.RoleMembership M ON (U.Name = M.UserName)
 	WHERE (M.RoleName = :pRoleName) AND (U.IsActive = 1)
 	ORDER BY Tasks,Ranking Desc
	)

	&sql(OPEN sql1)
	&sql(FETCH sql1)
	While (SQLCODE = 0) {
		If (tIsActive) {
			Set pUserName = tName
			Set pCount = tTasks
			Quit
		}
		&sql(FETCH sql1)
	}
	&sql(CLOSE sql1)

	Quit tSC
}

/// Returns a set of tasks for the current user.
Query ListTasksForCurrentUser() As %SQLQuery
{
	SELECT %ID As ID,
			(CASE WHEN IsNew = 1 THEN '*' ELSE NULL END) As New,
			Task->%Priority As Priority,
			Task->%Subject As Subject,
			Left(Task->%Message,25) As Message,
			Task As TaskId,
			RoleName,
			Task->TaskStatus_AssignedTo As AssignedTo,
			TimeCreated,
			Age,
			UserName
	FROM Worklist
 	WHERE (UserName = USER) 
 		AND ((Task->TaskStatus_AssignedTo IS NULL) OR (Task->TaskStatus_AssignedTo = UserName))
	ORDER BY TimeCreated DESC
}

/// Returns count of tasks for the current user.
ClassMethod CountTasksForCurrentUser() As %Integer
{
	Set tCount = 0
	&sql(SELECT COUNT(*) INTO :tCount
		FROM Worklist
 		WHERE (UserName = USER) 
 			AND ((Task->TaskStatus_AssignedTo IS NULL) OR (Task->TaskStatus_AssignedTo = UserName)))
 			
 	Quit tCount
}

/// Returns a set of tasks for the specified user.
Query ListTasksForUser(pUser As %String = "") As %SQLQuery
{
	SELECT %ID As ID,
			(CASE WHEN IsNew = 1 THEN 'New' ELSE '' END) As New,
			Task->%Priority As Priority,
			TimeCreated,
			Age,
			RoleName,
			Task->TaskStatus_AssignedTo As AssignedTo,
			UserName,
			Task->%Subject As Subject,
			Left(Task->%Message,25) As Message
	FROM Worklist
 	WHERE (UserName = :pUser)
 		AND ((Task->TaskStatus_AssignedTo IS NULL) OR (Task->TaskStatus_AssignedTo = UserName))
	ORDER BY TimeCreated DESC
}

/// Returns a set of tasks for the specified role.
Query ListTasksForRole(pRole As %String = "") As %SQLQuery
{
	SELECT %ID As TaskId,
			TaskStatus_RoleName As RoleName,
			TaskStatus_IsComplete As IsComplete,
			%Status As Status,
			%Priority As Priority,
			TaskStatus_Source As Source,
			TaskStatus_AssignedTo As AssignedTo,
			%Subject As Subject,
			TaskStatus_TimeCreated As TimeCreated,
			TaskStatus_TimeCompleted As TimeCompleted
	FROM TaskResponse
	WHERE TaskStatus_RoleName = :pRole
	ORDER BY TaskId DESC
}

/// Returns set of all available Users.
Query ListUsers() As %SQLQuery
{
SELECT 	U.Name,
 		U.FullName,
 		U.IsActive,
		(SELECT COUNT(*) FROM RoleMembership WHERE UserName = U.Name) As Roles
		FROM UserDefinition U
		ORDER BY U.Name
}

/// Returns set of Roles for a given User.
Query RolesForUser(pUserName As %String = "") As %SQLQuery
{
SELECT RoleName FROM RoleMembership
WHERE UserName = :pUserName
ORDER BY RoleName
}

/// Returns all users that are active.
Query ListActiveUsers() As %SQLQuery
{
	SELECT Name
	FROM UserDefinition
	WHERE IsActive = 1
	ORDER BY Name
}

/// Returns a set of users for the specified role.
Query ListUsersForRole(pRole As %String = "") As %SQLQuery
{
	SELECT 	UserName,
			UserName->FullName As FullName,
			Ranking,
			Title,
			UserName->IsActive
	FROM RoleMembership
	WHERE RoleName = :pRole
	ORDER BY UserName
}

/// Returns a set of roles for the specified user.
Query ListRolesForUser(pUser As %String = "") As %SQLQuery
{
	SELECT 	RoleName,
			Ranking,
			Title
	FROM RoleMembership
	WHERE UserName = :pUser
	ORDER BY RoleName
}

/// Returns a set of workflow tasks.
Query Tasklist() As %SQLQuery
{
	SELECT %ID As TaskId,
			TaskStatus_RoleName As RoleName,
			TaskStatus_IsComplete As IsComplete,
			%Status As Status,
			%Priority As Priority,
			TaskStatus_Source As Source,
			TaskStatus_AssignedTo As AssignedTo,
			%Subject As Subject,
			TaskStatus_TimeCreated As TimeCreated,
			TaskStatus_TimeCompleted As TimeCompleted,
			DATEDIFF('ss',TaskStatus_TimeCreated,TaskStatus_TimeCompleted) As Duration
	FROM TaskResponse
	ORDER BY TaskId DESC
}

/// Returns the current worklist contents for all users.
Query Worklist() As %SQLQuery
{
	SELECT %ID As ItemId,
			Task As TaskId,
			UserName,
			RoleName,
			Task->%Priority As Priority,
			TimeCreated,
			Age,
			Task->TaskStatus_AssignedTo As AssignedTo,
			Task->%Subject As Subject
	FROM Worklist
	ORDER BY TimeCreated DESC
}

/// Business Activity Metrics query to get information on current task load.<br>
/// This query returns the number of active tasks for each role.<br>
/// Use the Bam methods to get this information, not this query.
Query ListActiveTasks() As %SQLQuery
{
	SELECT 	R.Name As RoleName,
		(SELECT COUNT(*) 
			FROM TaskResponse 
			WHERE (TaskStatus_RoleName = R.Name) AND (TaskStatus_IsComplete = 0)) 
			As ActiveTasks,
		(SELECT COUNT(*) 
			FROM TaskResponse 
			WHERE (TaskStatus_RoleName = R.Name) AND (TaskStatus_IsComplete = 0)) / Capacity * 100
			As Load
	FROM RoleDefinition R
}

/// Business Activity Metrics query to get information on completed tasks.<br>
/// Use the Bam methods to get this information, not this query.
Query ListCompletedTasks(pStart As %TimeStamp = "") As %SQLQuery
{
	SELECT 	R.Name As RoleName,
		(SELECT COUNT(*)
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated > :pStart) AND (TaskStatus_RoleName = R.Name) AND (TaskStatus_IsComplete = 1)) 
			As CompletedTasks,
			(SELECT AVG(DATEDIFF('ss',TaskStatus_TimeCreated,TaskStatus_TimeCompleted))
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated > :pStart) AND (TaskStatus_RoleName = R.Name) AND (TaskStatus_IsComplete = 1)) 
			As AverageTime,
			(SELECT MIN(DATEDIFF('ss',TaskStatus_TimeCreated,TaskStatus_TimeCompleted))
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated > :pStart) AND (TaskStatus_RoleName = R.Name) AND (TaskStatus_IsComplete = 1)) 
			As MinTime,
			(SELECT MAX(DATEDIFF('ss',TaskStatus_TimeCreated,TaskStatus_TimeCompleted))
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated > :pStart) AND (TaskStatus_RoleName = R.Name) AND (TaskStatus_IsComplete = 1)) 
			As MaxTime
	FROM RoleDefinition R
}

/// Helper method to create an object instance given a class name.
ClassMethod %CreateObject(pClass As %String) As %RegisteredObject
{
	Set tObj = ""
	Set $ZT = "Trap"
	Set tObj = $zobjclassmethod(pClass,"%New")
Done
	Quit tObj
Trap
	Set $ZT = ""
	Set tObj = ""
	Goto Done
}

/// Test if a worklist item exists for the given Task and User name.
/// Put here in order to inline
ClassMethod ItemExistsForTask(pTask As EnsLib.Workflow.TaskResponse, pUserName As %String) As %Boolean [ CodeMode = expression ]
{
''$D(^EnsLib.W.WorklistD(pTask,pUserName))
}

/// Takes a Task and distributes it, via a Task object, to a role.
/// Called by Workflow operation when a new task arrives.
ClassMethod %DistributeTask(pRoleName As %String, pRequest As TaskRequest, pToken As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		// open role
		Set tRole = ##class(RoleDefinition).%OpenId(pRoleName)
		If ('$IsObject(tRole)) {
			Set tSC = $$$EnsError($$$EnsWfErrRoleUndefined, pRoleName)
			Quit
		}
		
		// find message header info for task
		Set tRequestId = pRequest.%Id()
		Set tRequestBodyClassName = $classname(pRequest)
		Set tSource = "", tSessionId = ""

		&SQL(
			SELECT SourceConfigName,SessionId 
			INTO :tSource, :tSessionId
			FROM Ens.MessageHeader
			WHERE MessageBodyId = :tRequestId AND MessageBodyClassName = :tRequestBodyClassName
		)

		// create final response for task
		// this is used to manage the state of the task
		// the response type must be a subclass of EnsLib.Workflow.TaskResponse
		// this can be overidden via the %TaskHandler property of
		// the request object.
		// If %TaskHandler is not provided, then the default response
		// class for the request object (specified by its RESPONSECLASSNAME parameter)
		// is used.
		
		If (pRequest.%TaskHandler = "") {
			// use default
			Set tSC = pRequest.NewResponse(.tTask)
			If $$$ISERR(tSC) {
				Set tTask=""
			}
		}
		Else {
			// create the request class
			Set tTask = ..%CreateObject(pRequest.%TaskHandler)
		}
		
		If ('$IsObject(tTask)) {
			/// return error to caller
			Set tSC = $$$EnsError($$$EnsWfErrTaskCreateFailure,pRequest.%TaskHandler)
			Quit
		}
		If ('tTask.%IsA("EnsLib.Workflow.TaskResponse")) {
			/// return error to caller
			Set tSC = $$$EnsError($$$EnsWfErrTaskWrongType, $classname(tTask))
			Quit
		}

		// Set Task properties		
		Set tTask.%RoleName = pRoleName
		Set tTask.%Status = $$$WfTaskUnassigned

		// fill in Task status
		Set tTask.%TaskStatus.ResponseToken = pToken
		Set tTask.%TaskStatus.Role = tRole
		Set tTask.%TaskStatus.Request = pRequest
		Set tTask.%TaskStatus.Source = tSource
		Set tTask.%TaskStatus.SessionId = tSessionId
		Set tTask.%TaskStatus.AssignedTo = ""
		
		// copy form-related values into Task
		Set tTask.%Priority = pRequest.%Priority
		Set tTask.%FormValues = pRequest.%FormValues
		Set tTask.%FormFields = pRequest.%FormFields
		Set tTask.%FormTemplate = pRequest.%FormTemplate
		Set tTask.%Subject = pRequest.%Subject
		Set tTask.%Message = pRequest.%Message
		Set tTask.%Actions = pRequest.%Actions

		// make sure task has an ID
		Set tSC = tTask.%Save()
		If $$$ISERR(tSC) Quit

		// notify Task object
		Set tSC = tTask.OnNewTask(pRequest)
		If $$$ISERR(tSC) Quit

		// save to make sure user changes are saved
		Set tSC = tTask.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// A request to assign a task to specific user
/// Called by Workflow Form when User requests onwership.
ClassMethod %TakeOwnershipForTask(pItemId As %String, pUser As %String, ByRef pMsg As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set pMsg = ""
	
	Do {
		// open worklist item
		Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(pItemId,4,.tSC)
		If $$$ISERR(tSC) Quit
		
		// note that the user has seen this item
		Set tItem.IsNew = 0

		// update worklist item
		Set tSC = tItem.%Save()
		If $$$ISERR(tSC) Quit

		// explicitly open associated task
		Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(tItem.TaskGetObjectId(),4,.tSC)
		If $$$ISERR(tSC) Quit

		// serial access to task		
		// make sure that nobody has already grabbed this
		If (tTask.%TaskStatus.AssignedTo '= "") {
			// unable to take ownership
			Set pMsg = "This task is already assigned to " _ tTask.%TaskStatus.AssignedTo
			Quit
		}

		// notify Task to perform the assignment
		Set tSC = tTask.OnAssign(pUser)
		If $$$ISERR(tSC) Quit

		// save to make sure user changes are saved
		Set tSC = tTask.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// A request to unassign an assigned task.
/// Called by Workflow Form when User requests task relinquishment.
ClassMethod %RelinquishOwnershipForTask(pItemId As %String, pUser As %String, ByRef pMsg As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set pMsg = ""
	
	Do {
		// open item
		Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(pItemId,-1,.tSC)
		If $$$ISERR(tSC) Quit
		
		// explicitly open associated task
		Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(tItem.TaskGetObjectId(),4,.tSC)
		If $$$ISERR(tSC) Quit

		// make sure that we are the owner
		If (tTask.%TaskStatus.AssignedTo '= pUser) {
			// unable to take ownership
			Set pMsg = "This task is assigned to " _ tTask.%TaskStatus.AssignedTo
			Quit
		}

		// notify Task to unassign
		Set tSC = tTask.OnRelinquish(pUser)
		If $$$ISERR(tSC) Quit

		// save to make sure user changes are saved
		Set tSC = tTask.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// A request to process an action for a task.
/// Called by Workflow Form when User makes an Action.
ClassMethod %ProcessAction(pActionId As %String, pItemId As %String, pUserName As %String, ByRef pMsg As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Set pMsg = ""
	
	Do {
		Set tComplete = 0

		// open worklist item
		Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(pItemId,4,.tSC)
		If $$$ISERR(tSC) Quit
		
		// explicitly open task to unassign and check for completion
		Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(tItem.TaskGetObjectId(),4,.tSC)
		If $$$ISERR(tSC) Quit
		
		If (tTask.%TaskStatus.AssignedTo '= tItem.UserGetObjectId()) {
			// does not belong to us
			Set pMsg = "This task is not assigned to the current user."
			Quit
		}

		// notify Task that action has occurred
		Set tSC = tTask.OnAction(pActionId)
		If $$$ISERR(tSC) Quit

		// save to make sure user changes are saved
		Set tSC = tTask.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Cancel a workflow task.
/// Called when original request times out.
ClassMethod %CancelRequest(pRequest As TaskRequest) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK

	Do {
		// find the task for the request
		Set tRequestId = pRequest.%Id()

		&SQL(
			SELECT %ID
			INTO :tTaskId
			FROM TaskResponse
			WHERE TaskStatus_Request = :tRequestId
		)

		Set tTask = ##class(TaskResponse).%OpenId(tTaskId,4,.tSC)
		If $$$ISERR(tSC) Quit
		
		// delete the worklist items associated with this task
		&sql(DELETE FROM Worklist WHERE Task = :tTaskId)
		If (SQLCODE < 0) Set tSC = $$$ERROR($$$EnsErrGeneral,"While assigning a task, delete from Worklist failed with SQLCODE "_SQLCODE)

		// notify Task		
		Set tSC = tTask.OnCancel()
		If $$$ISERR(tSC) Quit

		// mark task as discarded, unassign, mark as complete
		Set tTask.%Status = $$$WfTaskDiscarded
		Set tTask.%TaskStatus.AssignedTo = ""
		Set tTask.%TaskStatus.IsComplete = 1
		Set tTask.%TaskStatus.TimeCompleted = $$$timeUTC
		Set tSC = tTask.%Save()
		If $$$ISERR(tSC) Quit
		
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Notification that a Role definition has been changed.<br>
/// Possible values for <var>pReason</var> are:
/// <ul>
/// <li>$$$WfRoleDeleted--The role has been deleted.</li>
/// </ul>
ClassMethod %OnRoleChange(pRoleName As %String, pReason As %String) As %Status
{
	// do nothing for now
	Quit $$$OK
}

/// Notification that the Role membership has been changed.<br>
/// Possible values for <var>pReason</var> are:
/// <ul>
/// <li>$$$WfUserAddedToRole--A user has been added to the role.</li>
/// <li>$$$WfUserRemovedFromRole--A user has been removed from the role.</li>
/// </ul>
ClassMethod %OnRoleMembershipChange(pRoleName As %String, pReason As %String, pUserName As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK

	Do {
		If (pReason = $$$WfUserRemovedFromRole) {
			// find all worklist items for this user (within this role) and
			// delete or unassign them

			&sql(DECLARE worklist2 CURSOR FOR
				SELECT %ID,Task,Task->TaskStatus_AssignedTo
				INTO :tItemId, :tTaskId, :tAssign
				FROM Worklist
				WHERE (UserName = :pUserName) AND (RoleName = :pRoleName)
			)
			&sql(OPEN worklist2)
			&sql(FETCH worklist2)
			While (SQLCODE = 0) {
				Set tOwner = 0
				If (tAssign = pUserName) {
					Set tOwner = 1

					// unassign this item
					Set tSC = ..%RelinquishOwnershipForTask(tItemId, pUserName,.tMsg)
					If $$$ISERR(tSC) Quit
				}
	
				// delete the worklist item
				&sql(DELETE FROM Worklist 
						WHERE (%ID = :tItemId) )
				If (SQLCODE < 0) Set tSC = $$$ERROR($$$EnsErrGeneral,"While assigning a task, delete from Worklist failed with SQLCODE "_SQLCODE)
	
				// notify Task that user is changed
				// explicitly open associated task
				Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(tTaskId,4,.tSC)
				If ($$$ISOK(tSC) && $IsObject(tTask)) {
					Set tSC = tTask.OnRoleChange(pUserName,pReason,tOwner)
					If $$$ISERR(tSC) Quit

					// save to make sure user changes are saved
					Set tSC = tTask.%Save()
					If $$$ISERR(tSC) Quit

					Set tTask = ""
				}

				// next item	
				&sql(FETCH worklist2)
			}
			&sql(CLOSE worklist2)
		}
		ElseIf (pReason = $$$WfUserAddedToRole) {
			Set tUserObj = ##class(EnsLib.Workflow.UserDefinition).%OpenId(pUserName)
			If '$IsObject(tUserObj) {
				Set tSC = $$$EnsError($$$EnsWfErrUserUndefined, pUserName)
				Quit
			} Else {
				If 'tUserObj.IsActive Quit
			}
			Set tUserObj = ""
			// put all unassigned tasks into new user's worklist
			&sql(DECLARE tasks2 CURSOR FOR
				SELECT %ID INTO :tItemId
				FROM TaskResponse 
				WHERE (TaskStatus_RoleName = :pRoleName) 
					AND (TaskStatus_AssignedTo IS NULL)
					AND (TaskStatus_IsComplete = 0)
			)
			&sql(OPEN tasks2)
			&sql(FETCH tasks2)
			While (SQLCODE = 0) {
				
				#; send unassigned task to user
				Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(tItemId)
				If $IsObject(tTask) {
					Set tSC = ..SendTask(tTask, pUserName)
					If $$$ISERR(tSC) Quit
				}				
				#; next item	
				&sql(FETCH tasks2)
			}
			&sql(CLOSE tasks2)
		}

	} While(0)

Done
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Notification that a User definition has been changed.<br>
/// Possible values for <var>pReason</var> are:
/// <ul>
/// <li>$$$WfUserDeleted--The user has been deleted.</li>
/// <li>$$$WfUserInactivated--The user has been inactivated.</li>
/// <li>$$$WfUserActivated--The previously inactive user has been activated.</li>
/// </ul>
ClassMethod %OnUserChange(pUserName As %String, pReason As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		If (pReason = $$$WfUserDeleted)||(pReason = $$$WfUserInactivated) {
			// find all worklist items for this user and
			// delete or unassign them
	
			&sql(DECLARE worklist CURSOR FOR
				SELECT %ID,Task,Task->TaskStatus_AssignedTo
				INTO :tItemId, :tTaskId, :tAssign
				FROM Worklist
				WHERE (UserName = :pUserName)
			)
			&sql(OPEN worklist)
			&sql(FETCH worklist)
			While (SQLCODE = 0) {
				Set tOwner = 0
				If (tAssign = pUserName) {
					Set tOwner = 1

					// unassign this item
					Set tSC = ..%RelinquishOwnershipForTask(tItemId, pUserName,.tMsg)
					If $$$ISERR(tSC) Quit
				}
	
				// delete the worklist item
				&sql(DELETE FROM Worklist 
						WHERE (%ID = :tItemId) )
				If (SQLCODE < 0) Set tSC = $$$ERROR($$$EnsErrGeneral,"While assigning a task, delete from Worklist failed with SQLCODE "_SQLCODE)
	
				// notify Task that user is changed
				// explicitly open associated task
				Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(tTaskId,4,.tSC)
				If ($$$ISOK(tSC) && $IsObject(tTask)) {
					Set tSC = tTask.OnRoleChange(pUserName,pReason,tOwner)
					If $$$ISERR(tSC) Quit

					// save to make sure user changes are saved
					Set tSC = tTask.%Save()
					If $$$ISERR(tSC) Quit
				
					Set tTask = ""
				}

				// next item	
				&sql(FETCH worklist)
			}
			&sql(CLOSE worklist)
		} 
		#; Set ^Ens.Workflow("NotifyOnUserActivation") to 0 to prevent the Workflow Engine
		#; picking up all unassigned tasks in roles to which the user belongs
		ElseIf (pReason = $$$WfUserActivated)&&($get(^Ens.Workflow("NotifyOnUserActivation"),1)) {
			#; Find roles for user
			Set tRoleRS = ##class(%ResultSet).%New("EnsLib.Workflow.Engine:ListRolesForUser")
			
			Set tSC = tRoleRS.Execute(pUserName)
			If $$$ISERR(tSC) Quit
			
			Set tSQL = "SELECT %ID As ID FROM EnsLib_Workflow.TaskResponse "
						_ "WHERE (TaskStatus_RoleName = ?) "
						_ "AND (TaskStatus_AssignedTo IS NULL) "
						_ "AND (TaskStatus_IsComplete = 0)"
			
			While tRoleRS.Next(.tSC) {
				If $$$ISERR(tSC) Quit
				Set tRole = tRoleRS.Get("RoleName")
				If tRole = "" Continue
				
				#; Find unassigned tasks for role
				Set tTaskRS = ##class(%ResultSet).%New()
				Set tSC = tTaskRS.Prepare(tSQL)
				If $$$ISERR(tSC) Quit
				Set tSC = tTaskRS.Execute(tRole)
				If $$$ISERR(tSC) Quit
				While tTaskRS.Next(.tSC) {
					If $$$ISERR(tSC) Quit
					Set tTaskID = tTaskRS.Get("ID")
					If tTaskID = "" Continue
					
					#; send unassigned task to user
					Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(tTaskID)
					If $IsObject(tTask) {
						Set tSC = ..SendTask(tTask, pUserName)
						If $$$ISERR(tSC) Quit
					}				
				}
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit
		}
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Calculate the number of Active Tasks for a given role.<br>
/// Active Tasks is the number of tasks that are not marked as complete.
ClassMethod BamActiveTasks(pRole As %String) As %Integer
{
	Set tResult = 0
	
	// active tasks
	&sql(
		SELECT COUNT(*) INTO :tResult
		FROM TaskResponse 
		WHERE (TaskStatus_RoleName = :pRole) 
			AND (TaskStatus_IsComplete = 0)
	)
	
	Quit +tResult
}

/// Calculate the Active Load for a given role.<br>
/// Active Load is the number of active tasks expressed as a percentage of
/// the given role's capacity setting:<br>
/// ActiveLoad = (ActiveTasks / Role.Capacity) * 100
ClassMethod BamActiveLoad(pRole As %String) As %Integer
{
	Set tSC = $$$OK
	Set tResult = 0
	
	Do {
		// active tasks
		Set tTasks = ..BamActiveTasks(pRole)

		// find role
		Set tRoleDef = ##class(RoleDefinition).%OpenId(pRole)
		If '$IsObject(tRoleDef) Quit

		// load
		If (tRoleDef.Capacity > 0) {
			Set tResult = 100 * (tTasks / tRoleDef.Capacity)
		}

	} While(0)
	
	Quit +tResult
}

/// Calculate the number of Completed Tasks for a given role
/// created within the given time window.<br>
/// <var>pStart</var> and <var>pEnd</var> are in in %TimeStamp format: yyyy-mm-dd
ClassMethod BamCompletedTasks(pRole As %String, pStart As %TimeStamp = "", pEnd As %TimeStamp = "") As %Integer
{
	Set tResult = 0
	Set:pEnd="" pEnd = $$$timeUTC
	
	&sql(
		SELECT COUNT(*) INTO :tResult
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated >= :pStart) 
				AND (TaskStatus_TimeCreated <= :pEnd) 
				AND (TaskStatus_RoleName = :pRole) 
				AND (TaskStatus_IsComplete = 1)
	)

	Quit +tResult
}

/// Calculate the number of Tasks for a given role
/// that have a given status value (e.g, "Cancelled", "Completed") 
/// created within the given time window.<br>
/// <var>pStart</var> and <var>pEnd</var> are in in %TimeStamp format: yyyy-mm-dd
ClassMethod BamTasksWithStatus(pRole As %String, pStatus As %String, pStart As %TimeStamp = "", pEnd As %TimeStamp = "") As %Integer
{
	Set tResult = 0
	Set:pEnd="" pEnd = $$$timeUTC
	
	&sql(
		SELECT COUNT(*) INTO :tResult
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated >= :pStart) 
				AND (TaskStatus_TimeCreated <= :pEnd) 
				AND (%Status = :pStatus) 
				AND (TaskStatus_RoleName = :pRole) 
	)

	Quit +tResult
}

/// Calculate the average duration (in seconds) of Completed Tasks for a given role
/// created within the given time window.<br>
/// <var>pStart</var> and <var>pEnd</var> are in in %TimeStamp format: yyyy-mm-dd
ClassMethod BamAvgTaskTime(pRole As %String, pStart As %TimeStamp = "", pEnd As %TimeStamp = "") As %Integer
{
	Set tResult = 0
	Set:pEnd="" pEnd = $$$timeUTC
	
	&sql(
		SELECT 
			AVG(DATEDIFF('ss',TaskStatus_TimeCreated,TaskStatus_TimeCompleted)) 
			INTO :tResult
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated >= :pStart) 
				AND (TaskStatus_TimeCreated <= :pEnd) 
				AND (TaskStatus_RoleName = :pRole) 
				AND (TaskStatus_IsComplete = 1)
	)

	Quit +tResult
}

/// Calculate the minimum duration (in seconds) of Completed Tasks for a given role
/// created within the given time window.<br>
/// <var>pStart</var> and <var>pEnd</var> are in in %TimeStamp format: yyyy-mm-dd
ClassMethod BamMinTaskTime(pRole As %String, pStart As %TimeStamp = "", pEnd As %TimeStamp = "") As %Integer
{
	Set tResult = 0
	Set:pEnd="" pEnd = $$$timeUTC
	
	&sql(
		SELECT 
			MIN(DATEDIFF('ss',TaskStatus_TimeCreated,TaskStatus_TimeCompleted)) 
			INTO :tResult
			FROM TaskResponse 
			WHERE (TaskStatus_TimeCreated >= :pStart) 
				AND (TaskStatus_TimeCreated <= :pEnd) 
				AND (TaskStatus_RoleName = :pRole) 
				AND (TaskStatus_IsComplete = 1)
	)

	Quit +tResult
}

/// Calculate the maximum duration (in seconds) of Completed Tasks for a given role
/// created within the given time window.<br>
/// <var>pStart</var> and <var>pEnd</var> are in in %TimeStamp format: yyyy-mm-dd
ClassMethod BamMaxTaskTime(pRole As %String, pStart As %TimeStamp = "", pEnd As %TimeStamp = "") As %Integer
{
	Set tResult = 0
	Set:pEnd="" pEnd = $$$timeUTC
	
	&sql(
		SELECT 
			MAX(DATEDIFF('ss',TaskStatus_TimeCreated,TaskStatus_TimeCompleted)) 
			INTO :tResult
			FROM TaskResponse 
			WHERE 
				(TaskStatus_TimeCreated >= :pStart) 
				AND (TaskStatus_TimeCreated <= :pEnd) 
				AND (TaskStatus_RoleName = :pRole) 
				AND (TaskStatus_IsComplete = 1)
	)
	
	Quit +tResult
}

}
