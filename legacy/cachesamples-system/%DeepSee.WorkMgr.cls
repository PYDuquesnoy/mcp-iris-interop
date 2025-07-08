/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %syPidtab, %occErrors)

IncludeGenerator (%occUtility, %DeepSee)

///  Utility class that provides an API for managing
///  DeepSee tasks.<br/>
///  This is an internal utility used by DeepSee.
Class %DeepSee.WorkMgr Extends %RegisteredObject [ System = 3 ]
{

///  Name of system used to talk to agents.
Parameter EVENTNAME = "^DeepSee.Tasks.";

///  Timeout value (seconds) for events.
///  If no events are received, then the agent will shut itself down.
Parameter TIMEOUT = 0;

/// Turn on logging for the DeepSee background agents. These will be reset during a call to <method>%KillLog</method>.
ClassMethod %SetLoggingOptions(pUseArchive = 0, pLogSize = 100, pLogAll = 0)
{
	// Method added by DTB256
	Set $$$DeepSeeAgentLogGLVN("settings","useArchive") = pUseArchive
	Set $$$DeepSeeAgentLogGLVN("settings","logSize") = pLogSize
	Set $$$DeepSeeAgentLogGLVN("settings","logAll") = pLogAll
}

///  Reset the WorkMgr.<br/>
///  This stops all running agents, clears out all tasks, and clears the logs.
ClassMethod %Reset() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.WorkMgr).%KillAgents(1)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%DeepSee.WorkMgr).%KillLog()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

///  WorkQ agents will be made available as needed. This test always returns True
ClassMethod %IsActive() As %Boolean
{
	Quit 1
}

///  Wrapper for the WorkMgr:Sync() that parallels the original %DeepSee.TaskMaster version.
/// The caller may optionally supply an object reference to a <var>pWorkMgr</var> for custom use.
ClassMethod %WaitForTaskGroup(ByRef pTaskGroup As %String = "", Output pCompleted As %Boolean, pTimeOut As %Integer = 0, ByRef pWorkMgr As %SYSTEM.WorkMgr = {$$$NULLOREF}, Output pMaxTaskGroupWorkers As %Integer, Output pMaxWorkersOverallSoFar As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pCompleted = 0

	Try {		
		Set tReuseWorkMgr = $IsObject(pWorkMgr)&&pWorkMgr.%IsA("%SYSTEM.WorkMgr")		// DTB923
		
		If tReuseWorkMgr {		// DTB923
			Set tWorkMgr = pWorkMgr
		}
		Else {
			Set tWorkMgr = ..%AttachToQueue(pTaskGroup,.tSC)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		}
		
		// DP-415779 - Wait for the current workMgr to complete its tasks. The wait strategy is to poll the
		// WorkMgr's internal accounting on a small interval, while cross-checking that with the user
		// timeout request. If the user's timeout is reached before work is complete, return to the caller
		// and allow work to continue.
		// If there is a "stop" signal in the agents global, do not re-enter the wait loop and
		// instead kill the WorkMgr to shut down the work Q.
		Set tStop = 0				// Flag to signal a quit out of the wait loop
		Set tAccumWaitTime = 0		// Total wait time accumulated thus far
		Set tWaitInc = 0.1			// Individual target loop time
		While 'tStop {
			// Issue the wait to the work manager to check the status of the tasks
			Set tStart = $zh
			Set tSC = tWorkMgr.Wait(,.tAtEnd,tWaitInc)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			Do $I(tAccumWaitTime,$zh-tStart)

			If ('$D($$$DeepSeeAgentsGLVN("workToken",pTaskGroup),tToken)||(tToken="stop")) {
				// DP-415779 - Check the workToken for the interrupt signal. If an external process has set this signal, 
				// stop waiting for results and kill both references to the object to shut down all work.
				Set pWorkMgr = $$$NULLOREF
				Set pCompleted = 1		// Trigger local group cleanup
				Set tStop = 1

				// Write the interrupt message to the log and produce an error status to send back
				// to the caller
				Set tInterruptMsg = "Task group cancelled: "_pTaskGroup_" "_$G(%dsCubeName)
				Do ..%Log(tInterruptMsg)
				Set tSC = $$$ERROR($$$GeneralError,tInterruptMsg)
			}
			ElseIf ((pTimeOut>0)&&(tAccumWaitTime>pTimeOut)) {
				// The caller requested a maximum wait time which has been reached
				Set:tAtEnd pCompleted = 1
				Set tStop = 1
			}
			ElseIf tAtEnd {
				// Wait until the workMgr reports all tasks are complete
				Set pCompleted = 1
				Set tStop = 1
			}
		}

		If 'tReuseWorkMgr&&'pCompleted {
			// DTB - If not completed and the caller is not working with the WorkMgr directly, detach before returning
			Set tSC = ..%DetachFromQueue(pTaskGroup,.tWorkMgr)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	// General error
	If $$$ISERR(tSC) {
		Do ..%Log("ERROR:%WaitForTaskGroup:: "_$G(pTaskGroup,"Task Group Key Undefined")_" "_$G(%dsCubeName) _" :: "_ $system.Status.GetErrorText(tSC))
		Set pCompleted = 1
	}	

	// DP-415779 - Always run cleanup as a "finally" action. This covers both expected cleanup on completion 
	// and the event where execution was thrown from the try block
	If (pCompleted) {
		Kill tWorkMgr		// Close out the work queue and trigger overall cleanup

		Set tMaxTaskGroupWorkersExists = $D($$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, "max"), pMaxTaskGroupWorkers)
		Set pMaxWorkersOverallSoFar = +$G($$$DeepSeeAgentsGLVN("ActiveAgentsCount", "max"))		// DP-406819 - Protect read against missing value

		// DP-415779 - If this process is responsible for initiating the shutdown of the entire workload, it could circumvent the
		// WorkMgr's Cleanup callback. Call this manually for any process that is not shut down by the WorkMgr daemon. 
		Set tContext("queueID") = pTaskGroup
		Do ..%CleanupQueueContext(.tContext)
	}
	
	Quit tSC
}

/// Create a unique idenitfier for a task group. 
/// The caller may optionally request an object reference with <var>pRequestWorkMgr</var>=1 which
/// will be returned via <var>pWorkMgr</var> for customized use.
ClassMethod %CreateTaskGroup(Output pTaskGroup As %String, pWait As %Boolean = 0, pName As %String = "", pRequestWorkMgr = 0, Output pWorkMgr = {$$$NULLOREF}) As %Status
{
	Set tSC = $$$OK
		
	Try {
		Set pTaskGroup = "^DeepSee.TG." _ pName _ $I($$$DeepSeeTaskGroupGLVN)
		Set $$$DeepSeeTaskGroupGLVN(pTaskGroup,"wait") = pWait
		
		If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
			Do ..%Log("Task group create " _ pTaskGroup)
		}
		
		// DP-415779 - Initialize a workMgr along with the workToken index for allowing detached polling and interruption of work.
		// If requested, return the handle of the live object to the caller. Otherwise immediately detach and wait for work 
		// scheduling to reattach and manage future workflow.
		Set pWorkMgr = ..%InitializeWorkMgr(pTaskGroup,.tSC)
		If $$$ISERR(tSC) Quit
		If ('pRequestWorkMgr) {
			Set tSC = ..%DetachFromQueue(pTaskGroup,.pWorkMgr)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Do ..%Log("ERROR:%CreateTaskGroup: "_$System.Status.GetErrorText(tSC))
	}
	
	Quit tSC
}

/// Close down all work being done by this task group
ClassMethod %DestroyTaskGroup(pTaskGroup As %String = "", pPurgeTasks As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	
	Try {		
		// Prevent any other calls from picking up this work
		Lock +$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)
		
		// DTB706 - If there is no work token associated with this task group, don't bother attempting
		// to attach.
		If $D($$$DeepSeeAgentsGLVN("workToken",pTaskGroup),tToken) {
			If (tToken="") {
				// DP-415779 - If the token is null, it means a live workmgr is active somewhere else. 
				// Send the "stop" signal in this case since we don't know which process is currently
				// doing the work
				Set $$$DeepSeeAgentsGLVN("workToken",pTaskGroup) = "stop" 
				If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
					Do ..%Log("%DestroyTaskGroup: Issue stop signal for task group: " _ pTaskGroup)
				}
			}
			ElseIf (tToken'="")&&(tToken'="stop") {
				// DTB722 - Attach and tear down the WorkMgr if there is an attachment token defined.
				//   This will apply for any background queues that are awaiting assignments or doing 
				//   asynchronous work.
				// DP-415779 - (tToken="stop") is a no-op. 
				//   This occurs in a repeated call where the queue stop signal is set but hasn't been 
				//   processed by the live WorkMgr yet.
				Set tWorkMgr = ..%AttachToQueue(pTaskGroup,.tSC)
				If $$$ISERR(tSC) {
					Do ..%Log(tSC)
				}
				ElseIf $IsObject($G(tWorkMgr)) {
					Set tSC = tWorkMgr.Clear(0)
				}
				
				// Shut down the queue and clear the token slot.
				Kill tWorkMgr
				Kill $$$DeepSeeAgentsGLVN("workToken",pTaskGroup)		// Clear the work token container

				If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
					Do ..%Log("Task group destroyed " _ pTaskGroup)
				}
			}
		}
		Lock -$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)

		If pPurgeTasks {
			// Clean up globals
			Set tSC = ..%KillTasksForGroup(pTaskGroup)
		}
	}
	Catch ex {
		Lock -$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

///  - NOT IMPLEMENTED -
/// This is handled by the WorkQMgr as part of task queueing operations
ClassMethod %CreateAgents(pNumAgents As %Integer = "") As %Status
{
	// - NOT IMPLEMENTED -
	Quit $$$NotImplemented
}

/// Look up a token to reattach to a given WorkMgr queue.
/// After successfully serializing a WorkMgr instance, through either attachment to a pre-existing queue or initialization of a new queue,
/// the storage location for the provided <var>pQueueName</var> is marked with the null string to provide an indication the queue is
/// currently open and working.
ClassMethod %AttachToQueue(pQueueName As %String = "", Output pStatus As %Status = {$$$OK}) As %SYSTEM.WorkMgr
{
	Set tWorkMgr = $$$NULLOREF
	
	Try {
		Lock +$$$DeepSeeAgentsGLVN("workToken",pQueueName)

		If $D($$$DeepSeeAgentsGLVN("workToken",pQueueName),tToken) {
			If (tToken="stop") {
				// DP-415779 - Write the interrupt message to the log and produce an error status to 
				// send back to the caller. Leave the "stop" signal in the queue position in this case.
				Set tInterruptMsg = "Task group cancelled: "_pQueueName_" "_$G(%dsCubeName)
				Do ..%Log(tInterruptMsg)
				Set tSC = $$$ERROR($$$GeneralError,tInterruptMsg)
				$$$ThrowStatus(tSC)
			}
			ElseIf (tToken'="") {
				Set tWorkMgr = $system.WorkMgr.Attach(tToken,.tSC)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)

				Set $$$DeepSeeAgentsGLVN("workToken",pQueueName) = ""
			}
			Else {
				// This queue attempted to attach to a WorkMgr that has already been reattached
				Set pStatus = $$$ERROR($$$GeneralError,"No WorkMgr token available for "_pQueueName)
			}
		}
		Else {
			Set tWorkMgr = ..%InitializeWorkMgr(pQueueName,.pStatus)		// DTB923
		}

		Lock -$$$DeepSeeAgentsGLVN("workToken",pQueueName)
	}
	Catch ex {
		Lock -$$$DeepSeeAgentsGLVN("workToken",pQueueName)
		Set pStatus = ex.AsStatus()
	}
	
	Quit tWorkMgr
}

/// Detach from a given WorkMgr queue and store the current token needed to reattach.
/// If the storage location has been deleted before detaching from the queue (eg: by a cancellation operation),
/// then the token is discarded.
ClassMethod %DetachFromQueue(pQueueName As %String = "", ByRef pWorkMgr As %SYSTEM.WorkMgr = {$$$NULLOREF}) As %Status
{
	Set tSC = $$$OK
	
	Try {
		Lock +$$$DeepSeeAgentsGLVN("workToken",pQueueName)

		// DTB722 - Check the workToken index to confirm the existence of an active slot for this queue. 
		// DP-415779 - If the slot contains a stop signal, no further work should be done and the queue should 
		// simply be closed down.
		If $D($$$DeepSeeAgentsGLVN("workToken",pQueueName),tQueueSignal) {
			If (tQueueSignal="stop") {
				// DP-415779 - Write the interrupt message to the log and produce an error status to 
				// send back to the caller. Leave the "stop" signal in the queue position in this case.
				Set tInterruptMsg = "Task group cancelled: "_pQueueName_" "_$G(%dsCubeName)
				Do ..%Log(tInterruptMsg)
				Set tSC = $$$ERROR($$$GeneralError,tInterruptMsg)
				$$$ThrowStatus(tSC)
			}
			Else {
				// Detach and store the attachment token
				Set tSC = pWorkMgr.Detach(.tToken)
				
				If $$$ISERR(tSC) { 
					Quit
				}
				ElseIf (tToken'="") {
					Set $$$DeepSeeAgentsGLVN("workToken",pQueueName) = tToken
				}
			}
		}

		Lock -$$$DeepSeeAgentsGLVN("workToken",pQueueName)
	}
	Catch ex {
		Lock -$$$DeepSeeAgentsGLVN("workToken",pQueueName)
		Set tSC = ex.AsStatus()
	}

	Set pWorkMgr = $$$NULLOREF
	
	Quit tSC
}

/// Find all open WorkQ manager instances and shut them down
ClassMethod %KillAgents(pPurgeTasks As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	
	Try {
		If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
			Do ..%Log("%KillAgents called")
		}

		// DTB706 - Work through the current workToken index and shut down the WorkQ manager
		// instances associated with work dispatched using %DestroyTaskGroup
		Lock +$$$DeepSeeAgentsGLVN("workToken")
		Set tTaskGroup = $O($$$DeepSeeAgentsGLVN("workToken",""),1,tToken)
		While (tTaskGroup'="") {
			If (tToken="") {
				// If this is null when the lock is established, a different process has already attached to this queue.
				// DP-415779 - Send a stop signal to this queue
				Set $$$DeepSeeAgentsGLVN("workToken",tTaskGroup) = "stop"
				If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
					Do ..%Log("%KillAgents: Issue stop signal for task group: " _ tTaskGroup)
				}
			}
			Else {
				Set tSC = ..%DestroyTaskGroup(tTaskGroup)
			}
			
			Set tTaskGroup = $O($$$DeepSeeAgentsGLVN("workToken",tTaskGroup),1,tToken)
		}
		Lock -$$$DeepSeeAgentsGLVN("workToken")
		
		// DP-415779 - When cancelling work the management of this count is likely skipped, so this needs to be reset here.
		// Management of the max which relates to this running tally would have happened when an agent picks up work in %DequeueTask
		// and remains valid even through an agent reset.
		Kill $$$DeepSeeAgentsGLVN("ActiveAgentsCount","total")
		
		If (pPurgeTasks) {
			Kill $$$DeepSeeTasksGLVN
			Kill $$$DeepSeeActiveTasksGLVN
			Kill $$$DeepSeeTaskGroupGLVN
		}
	}
	Catch ex {
		Lock -$$$DeepSeeAgentsGLVN("workToken")
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// This performs the actual cleanup work to remove all tasks assigned to a particular logical work group.
ClassMethod %KillTasksForGroup(pTaskGroup As %String) As %Status
{
	// DTB706 - This works through the individual tasks assigned to a particular group and removes
	// all associated task information by ID
	Set tSC = $$$OK
	
	Try {
		Set tTaskId = $O($$$DeepSeeTaskGroupGLVN(pTaskGroup,"tasks",""))
		While (tTaskId'="") {
			Kill $$$DeepSeeTasksGLVN(tTaskId)
			Kill $$$DeepSeeActiveTasksGLVN(tTaskId)
			
			Set tTaskId = $O($$$DeepSeeTaskGroupGLVN(pTaskGroup,"tasks",tTaskId))		// DTB722 - Fix infinite loop from missing tTaskId start point
		}

		Kill $$$DeepSeeTaskGroupGLVN(pTaskGroup)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

///  This is called from the foreground to 
///  add a task to the queue of background tasks.<br/>
///  <var>pTaskGroup</var> must be defined in order to properly assign individual tasks
///  to a particular work queue.
///  The caller may optionally supply an object reference to a <var>pWorkMgr</var> to add 
///  the task to that custom work queue.
ClassMethod %QueueTask(pTaskGroup As %String = "", pTaskType As %String, pCubeName As %String, pQueryKey As %String = "", pData As %String = "", pData2 As %String = "", pData3 As %String = "", pSQLParams As %String = "", pSuppressArchive As %Boolean = 0, ByRef pWorkMgr As %SYSTEM.WorkMgr = {$$$NULLOREF}) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tReuseWorkMgr = $IsObject(pWorkMgr)&&pWorkMgr.%IsA("%SYSTEM.WorkMgr")		// DTB923
		/*
		// DTB - %ExecuteTask takes the following in its list parameters
		Set pTaskId = $LG(pParameters,1)
		Set pTaskType = $LG(pParameters,2)
		Set pCubeName = $LG(pParameters,3)
		Set pQueryKey = $LG(pParameters,4)
		Set pData = $LG(pParameters,5)
		Set pData2 = $LG(pParameters,6)
		Set pData3 = $LG(pParameters,7)
		Set pSQLParams = $LG(pParameters,8)
		*/
		
		Set tTaskId = $I($$$DeepSeeTasksGLVN)
		Set tTaskDetails = $LB(tTaskId,pTaskType,pCubeName,pQueryKey,pData,pData2,pData3,pSQLParams)
		
		If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
			Do ..%Log("Queue " _ pTaskType _ ":" _ pCubeName _ ":" _ pQueryKey _ ":: PARAMETERS:"  _ $ListToString(tTaskDetails,":"))
		}
		
		If (pTaskGroup'="") {
			If ($G($$$DeepSeeTaskGroupGLVN(pTaskGroup,"errorCode"))'="") {
				// don't even queue this task
				Set tSC = $$$DeepSeeTaskGroupGLVN(pTaskGroup,"errorCode")
				Quit
			}
			
			Set $$$DeepSeeTaskGroupGLVN(pTaskGroup,"tasks",tTaskId) = tTaskDetails
			Set x = $I($$$DeepSeeTaskGroupGLVN(pTaskGroup,"count"))
		}
		Else {
			// DTB - %QueueTask has been called without an established group
			Set tSC = $$$ERROR($$$GeneralError,"%QueueTask attempted without a task group")
			Quit
		}
		
		Set $$$DeepSeeTasksGLVN(tTaskId) = tTaskDetails
		
		// Make sure only one process queues to the WorkQ at a time
		Lock +$$$DeepSeeAgentsGLVN("workToken",pTaskGroup):1
		If '$TEST {
			Set tSC = $$$ERROR($$$GeneralError,"%QueueTask: Failure to lock workToken: "_pTaskGroup)
			$$$ThrowStatus(tSC)
		}
		
		// Attach to the task group's work manager
		If tReuseWorkMgr {		// DTB923
			// DP-415779 - Check for interrupt before queueing up work
			If ('$D($$$DeepSeeAgentsGLVN("workToken",pTaskGroup),tToken)||(tToken="stop")) {
				Set pWorkMgr = $$$NULLOREF

				Set tInterruptMsg = "Task group cancelled: "_pTaskGroup_" "_$G(%dsCubeName)
				Do ..%Log(tInterruptMsg)
				Set tSC = $$$ERROR($$$GeneralError,tInterruptMsg)
			}
			Else {
				Set tWorkMgr = pWorkMgr
			}
		}
		Else {
			Set tWorkMgr = ..%AttachToQueue(pTaskGroup,.tSC)
		}
		$$$ThrowOnError(tSC)
		
		If '$IsObject(tWorkMgr) {
			Set tSC = $$$ERROR($$$GeneralError,"Failure to instantiate work manager: "_pTaskGroup)
			$$$ThrowStatus(tSC)
		}
		
		Set tTaskSettings = {}
		Set tTaskSettings.suppressArchive = pSuppressArchive
		Set tTaskSettings.trace = +$G(%dstrace)
		Set tSC = tWorkMgr.Queue("##class(%DeepSee.WorkMgr).%ExecuteTask",pTaskGroup,tTaskDetails,tTaskSettings.%ToJSON())
		If $$$ISERR(tSC) {
			Do ..%Log("ERROR " _ pTaskType _ ":" _ pTaskGroup _ ":" _ tTaskId )
			$$$ThrowStatus(tSC)
		}
		
		If 'tReuseWorkMgr {
			// DTB - If the caller is not maintaining a live object, detach again 
			// The new token is stored under the queuename
			Set tSC = ..%DetachFromQueue(pTaskGroup,.tWorkMgr)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		}
		
		Lock -$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)
	}
	Catch(ex) {
		Lock -$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)
		Set tSC = ex.AsStatus()
	}	
	
	If $$$ISERR(tSC) {
		Do ..%Log("ERROR:%QueueTask: "_$System.Status.GetErrorText(tSC))
	}
	
	Quit tSC
}

///  - NOT IMPLEMENTED -
/// This is handled by the WorkQMgr.
ClassMethod %StartAgent(pAgentId As %String, pPriority As %String) [ Internal ]
{
	// - NOT IMPLEMENTED -
	$$$ThrowStatus($$$NotImplemented)
	Quit
}

/// This is called in %ExecuteTask to mark the task "active" in the process logging.
ClassMethod %DequeueTask(pTaskGroup As %String, pParameters As %List, pSuppressArchive As %Boolean = 0) As %Status
{
	// This does not do anything other than logging, it does not need to perform any execution function
	Set tSC = $$$OK
	
	Try {
		Set tTaskId = $LG(pParameters,1)
		Set tTaskType = $LG(pParameters,2)
		Set tCubeName = $LG(pParameters,3)
		Set tQueryKey = $LG(pParameters,4)
		Set tData = $LG(pParameters,5)
		Set tData2 = $LG(pParameters,6)
		Set tData3 = $LG(pParameters,7)
		Set tSQLParams = $LG(pParameters,8)
		
		If $G($$$DeepSeeAgentLogGLVN("settings","useArchive"),0)&&'pSuppressArchive {		// DTB302 - Check for archive suppression
			Set ^DeepSee.TaskArchive(tTaskId) = pParameters
		}
		
		// Mark this as an active task; remove item from queue
		Set $$$DeepSeeActiveTasksGLVN(tTaskId) = $LB($ZDT($ZTS,3,,3),$J,pTaskGroup) _ pParameters
		Kill $$$DeepSeeTasksGLVN(tTaskId)
		
			
		//APV008 - Updating number of workers being used
		S overallTotal = $I($$$DeepSeeAgentsGLVN("ActiveAgentsCount", "total"))
		S overallMax = $G($$$DeepSeeAgentsGLVN("ActiveAgentsCount", "max"))
		If (overallMax<overallTotal){
			S overallMax=overallTotal
		}
		S $$$DeepSeeAgentsGLVN("ActiveAgentsCount", "max") = overallMax
		
		
		Set $$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, $J)=""
		
		S currGroupTotal = $I($$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, "total"))
		S currGroupMax = $G($$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, "max"))
		
		If (currGroupMax<currGroupTotal){
			Set currGroupMax = currGroupTotal
		}
		S $$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, "max") = currGroupMax
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// This is called as the callback to %ExecuteTask which cleans up the management global. This
/// method will also close out the WorkQ if the group was created with pWait = 0.
ClassMethod %CloseTask(pTaskGroup As %String, pParameters As %List) As %Status
{
	// This does not do anything other than logging, it does not need to perform any execution function
	Set tSC = $$$OK
	
	Try {
		Set tTaskId = $LG(pParameters,1)
		Set tTaskType = $LG(pParameters,2)
		Set tCubeName = $LG(pParameters,3)
		Set tQueryKey = $LG(pParameters,4)
		Set tData = $LG(pParameters,5)
		Set tData2 = $LG(pParameters,6)
		Set tData3 = $LG(pParameters,7)
		Set tSQLParams = $LG(pParameters,8)
		
		// remove task from active list
		Kill $$$DeepSeeActiveTasksGLVN(tTaskId)
		
		// DTB923 - Note the completion of this task in the group log
		Kill $$$DeepSeeTaskGroupGLVN(pTaskGroup,"tasks",tTaskId)
		Set x = $I($$$DeepSeeTaskGroupGLVN(pTaskGroup,"complete"))
				
		//APV008
		Kill $$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, $J)
		
		Do $I($$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, "total"), -1)
		If (+$G($$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, "total"))<=0) Kill $$$DeepSeeAgentsGLVN("ActiveAgentsCount", pTaskGroup, "total")
		
		Do $I($$$DeepSeeAgentsGLVN("ActiveAgentsCount", "total"),-1)
		If (+$G($$$DeepSeeAgentsGLVN("ActiveAgentsCount", "total"))<=0) Kill $$$DeepSeeAgentsGLVN("ActiveAgentsCount", "total")
		
		If '$G($$$DeepSeeTaskGroupGLVN(pTaskGroup,"wait"),0) {
			// There will not be a call to wait for this group, close it down now.
			Lock +$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)
			Set tWorkMgr = ..%AttachToQueue(pTaskGroup,.tSC)
			$$$ThrowOnError(tSC)
			
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Task group complete: "_pTaskGroup_" "_$G(%dsCubeName))
			}
			
			// Clean up the task work.
			Set tContext("queueID") = pTaskGroup
			Do ..%CleanupQueueContext(.tContext)
			Kill tWorkMgr
			
			Lock -$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)
		}
	}
	Catch ex {
		Lock -$$$DeepSeeAgentsGLVN("workToken",pTaskGroup)
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// This is run by the worker and will do the actual work of processing tasks via the work queue manager
ClassMethod %ExecuteTask(pTaskGroup As %String, pParameters As %List, pSettings As %String = "") As %Status
{
	Set tSC = $$$OK
	
	Try {
		// Log this in the task queue to reflect the task is actually being picked up
		Set tSettingsObj = {}.%FromJSON(pSettings)
		Set tSuppressArchive = tSettingsObj.suppressArchive
		Set %dstrace = tSettingsObj.trace
		Set tSC = ..%DequeueTask(pTaskGroup,pParameters,tSuppressArchive)
		If $$$ISERR(tSC) Quit
		
		// pParameters = $LB(pTaskType As %String, pCubeName As %String, tQueryKey As %String, pData As %String, pData2 As %String, pData3 As %String, pSQLParams)
		Set tTaskId = $LG(pParameters,1)
		Set tTaskType = $LG(pParameters,2)
		Set tCubeName = $LG(pParameters,3)
		Set tQueryKey = $LG(pParameters,4)
		Set tData = $LG(pParameters,5)
		Set tData2 = $LG(pParameters,6)
		Set tData3 = $LG(pParameters,7)
		Set tSQLParams = $LG(pParameters,8)

		// DTB980 - Start a named timer that incorporates the specific task type
		$$$dsSetLogging
		$$$dsStartNamedTimer($$$dsCurrentMethod_":"_$G(tTaskType,"none"))

		$$$dsSetAppInfo($LB(pTaskGroup,pParameters))		// DP-419418 - Register with the activity monitor

		If (tTaskType = "EXECAXES") {
			// JMD1156
			Set tMDX = tData
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ ":" _ tCubeName _ ":" _ tQueryKey)
			}

			// JMD1387 ignore concurrency checks when executing axes in the background
			Set %dsForceQuery=1

			// JMD1395 pass filterSpec from foreground along
			Set %dsFilterSpec=tData2
			
			// + DTB943 - The variable tSQLParams contains two sets of contextual parameters:
			//  1) The parameters array originally passed into the original ExecuteAsynch() call
			//  2) The locks already held by the qeueing process	 
			Set tParmsList = $LG(tSQLParams,1)
			Set tLockKeysList = $LG(tSQLParams,2)
			
			Set tSC = ##class(%DeepSee.Utils).%ArrayFromList(tLockKeysList,.tLockKeys)		// DTB943 - Unpack the lock keys
			If $$$ISERR(tSC) Quit
			
			Set tSC = ##class(%DeepSee.Utils).%ArrayFromList(tParmsList,.tParms)		// DTB882 - Unpack the parameters
			If $$$ISERR(tSC) Quit
			// - DTB943
			
			// PFS079 - Extract variable info to pass into %PrepareMDX
			Set tVars = ""
			For tPos = 1:1:$ListLength(tData3) {
				Set tVar = $LG(tData3,tPos)
				Set tVars($LG(tVar,1)) = $LG(tVar,2)
			}


			// Prepare a background resultset to perform the actual work
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX(tMDX,.tVars)
			If $$$ISERR(tSC) Quit
			
			// + DTB943 - Set ancestor lock keys before requesting locks
			Set tSC = tRS.%SetAncestorLockKeys(.tLockKeys)
			If $$$ISERR(tSC) Quit
			// - DTB943

			// DTB884 - Always execute parameters and reset lock keys after executing parameters
			Do tRS.%ClearLockKeys()
			Set tSC = tRS.%ExecuteParameters(.tParms)
			If $$$ISERR(tSC) Quit
			
			// DTB943 - Manufacture the most recent keys, and signal this process is prepared
			// to hold the locks while waiting for results
			Do tRS.%SetLockKeys(1,1) 

			Kill %dsForceQuery
			Kill %dsFilterSpec

			// make sure execute uses background tasks
			Set tQuery = tRS.%GetQuery()
			
			// DTB788 - Run the query pre-processing to generate member providers
			Set tSC = tQuery.%PreProcessQuery()
			If $$$ISERR(tSC) Quit
			
			Set tQuery.useAgents = 1
			
			// + DTB868 - This process needs to be a writer to run %ExecuteAxes
			Set tSC = tRS.%SetLockMode("exclusive")
			If $$$ISERR(tSC) Quit
			
			While 'tRS.%AcquireLocks(.tSC)&&$$$ISOK(tSC) {
				Hang 0.1		// Wait to get locks and try again
				//Set:$$$ISOK(tSC) tSC = $$$ERROR($$$GeneralError,"Failed to obtain write locks for query::"_tCubeName_":"_tQueryKey)
			}
			If $$$ISERR(tSC) Quit
			// - DTB868
			
			Set tSC = tRS.%ExecuteAxes()
			// + WAL071 -- Axes only queries must do their own cleanup
			Set tCubeIndex = $$$DeepSeeIndex(tQuery.cube)
			Set tQueryKey = tQuery.%QueryKey
			// - WAL071
			If $$$ISERR(tSC) Quit

			// +DTB458 - Log the subquery keys in the results global if a related cube is involved
			Set tSubqueryCube = tRS.%CubeKey
			Set tSubqueryKey = tRS.%GetQueryKey()
			If ($G(tCubeIndex)'="") && (tQueryKey'="") && (tSubqueryCube'="") && (tSubqueryKey'="") && '((tSubqueryCube=$$$UPPER(tCubeIndex)) && (tQueryKey=tSubqueryKey)) {		// DTB670 - Fix condition to make sure self-referenced subqueries don't get logged
				Set $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"subquery",tSubqueryCube,tSubqueryKey) = "(9)"		// DTB614 - Use tCubeIndex in direct cache interactions
			}
			// -DTB458
			
			Do tRS.%ReleaseLocks()		// DTB868 - Release the locks

			// update stats
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ ":" _ tCubeName _ ":" _ tQueryKey)
			}
		}
		ElseIf (tTaskType = "EXECAXESANDQUERY") {
			Set tCubeIndex=$$$DeepSeeIndex(tCubeName)
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ ":" _ tCubeName _ ":" _ tQueryKey _ ":: PARAMETERS:"  _ $ListToString(pParameters,":"))
			}
			
			// The query string is being fetched from the Results cache into tMDX
			if ($Get($$$DeepSeeResultsGLVN(tCubeIndex, tQueryKey, "query", 0))=""){
				Set tMDX = $$$DeepSeeResultsGLVN(tCubeIndex, tQueryKey, "query", "keyText") 
			}		
			else{
				Set tMDX = $$$DeepSeeResultsGLVN(tCubeIndex, tQueryKey, "query", 0)
			}
			
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ " [axes]:" _ tCubeName _ ":" _ tQueryKey)
			}
			
			// + DTB943 - The variable tSQLParams contains two sets of contextual parameters:
			//  1) The parameters array originally passed into the original ExecuteAsynch() call
			//  2) The locks already held by the qeueing process	 
			Set tParmsList = $LG(tSQLParams,1)
			Set tLockKeysList = $LG(tSQLParams,2)
			
			Set tSC = ##class(%DeepSee.Utils).%ArrayFromList(tLockKeysList,.tLockKeys)		// DTB943 - Unpack the lock keys
			If $$$ISERR(tSC) Quit
			
			Set tSC = ##class(%DeepSee.Utils).%ArrayFromList(tParmsList,.tParms)		// DTB882 - Unpack the parameters
			If $$$ISERR(tSC) Quit
			// - DTB943
			
			// PFS079 - Extract variable info to pass into %PrepareMDX
			Set tVars = ""
			For tPos = 1:1:$ListLength(tData3) {
				Set tVar = $LG(tData3,tPos)
				Set tVars($LG(tVar,1)) = $LG(tVar,2)
			}
			
			
			// Prepare a background resultset to perform the actual work
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX(tMDX,.tVars)
			If $$$ISERR(tSC) Quit
			
			// + DTB943 - Set ancestor lock keys before requesting locks
			Set tSC = tRS.%SetAncestorLockKeys(.tLockKeys)
			If $$$ISERR(tSC) Quit
			// - DTB943
			
			// DTB884 - Always execute parameters and reset lock keys after executing parameters
			Do tRS.%ClearLockKeys()
			Set tSC = tRS.%ExecuteParameters(.pParms)
			If $$$ISERR(tSC) Quit
			
			// DTB943 - Manufacture the most recent keys, and signal this process is prepared
			// to hold the locks while waiting for results
			Do tRS.%SetLockKeys(1,1) 
			
			Set tQuery = tRS.%GetQuery()
			// DTB788 - Run the query pre-processing to generate member providers
			Set tSC = tQuery.%PreProcessQuery()
			If $$$ISERR(tSC) Quit
			// make sure execute uses background tasks
			Set tQuery.useAgents = 1
			
			// + DTB868 - This process needs to be a writer to run %ExecuteAxes
			Set tSC = tRS.%SetLockMode("exclusive")
			If $$$ISERR(tSC) Quit
			While 'tRS.%AcquireLocks(.tSC)&&$$$ISOK(tSC) {
				Hang 0.1		// Wait to get locks and try again
			}
			If $$$ISERR(tSC) Quit
			// - DTB868
			
			// DTB967 - If this query is marked that it must be computed, set the query object's
			// %recomputeAxes flag as would have been done in a synchronous foreground query.
			Set tMustCompute = $G($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"mustCompute"))
			If tMustCompute {
				Set tQuery.%recomputeAxes = 1
				Do tQuery.%ClearQueryResults()
			}
		

			// *** Begin Axes Execution ***
			Set tSC = tRS.%ExecuteAxes()
			
			// + WAL071 -- Axes only queries must do their own cleanup
			Set tCubeIndex = $$$DeepSeeIndex(tQuery.cube)
			Set tQueryKey = tQuery.%QueryKey		
			// - WAL071
			If $$$ISERR(tSC) Quit
			
			Set tVolume = +$G($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"cells"))
			If (tVolume <= 0) {
				Do ##class(%DeepSee.Utils).%WriteToLog("Query","NO VOLUME")
				// no more work to do
				Set $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"status") = 100
				Set $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"reason") = 2
				
				Quit
			}
			
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ " [axes]:" _ tCubeName _ ":" _ tQueryKey)
			}
			// *** Axes creation is complete ***
			
			
			// *** Begin Cell Calculation ***
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ " [cells]:" _ tCubeName _ ":" _ tQueryKey)
			}
			// clear stats
  			Kill $$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"Cells")
  			Kill $$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"Calcs")
			
			Set tSC = tRS.%ExecuteCells()
			If $$$ISERR(tSC) Quit
			// update stats
  			Set $$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"Cells") = +$G(tQuery.%Statistics("Cells"))
  			Set $$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"Calcs") = $G(tQuery.%Statistics("Calcs"))
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ " [cells]:" _ tCubeName _ ":" _ tQueryKey)
			}
			Do tRS.%ReleaseLocks()		// DTB868 - Release the locks
			
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ ":" _ tCubeName _ ":" _ tQueryKey)
			}
			
			// DP-405033 - Run the audit code in this background task to make sure it executes 
			// when the query is actually complete.
			Do tRS.%RunQueryAuditCode()
		}
		
		ElseIf (tTaskType = "EXECBUCKET") {
			// execute query for one bucket/section
			Set tBucket = tData
			Set tSlotNo = tData2
			Set tSectionList = tData3 // axis:start:end;
			Kill tSections
			If (tSectionList '= "") {
				For i = 1:1:$L(tSectionList,";") {
					Set x = $P(tSectionList,";",i)
					Set a = $P(x,":",1)
					Set tStart = $P(x,":",2)
					Set tEnd = $P(x,":",3)
					Set tSections(a) = $LB(tStart,tEnd)
				}
			}
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ ":" _ tCubeName _ ":" _ tQueryKey _ ":" _ tBucket _ " {" _tSectionList_"}")
			}

			Set tSC = ##class(%DeepSee.Query.Engine).%ExecuteForBucket(tCubeName,tQueryKey,tBucket,tSlotNo,.tSections,,.tStats)
			If $$$ISERR(tSC) Quit

			// update stats
  			Set x = $I($$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"Computes"),+$G(tStats($$$dsqStatCompute)))
  			Set x = $I($$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"CacheHits"),+$G(tStats($$$dsqStatCache)))

			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ ":" _ tCubeName _ ":" _ tQueryKey _ ":" _ tBucket _  " {" _tSectionList_"}")
			}
		}
		ElseIf (tTaskType = "UPDATEFACTS") {
			// update a range of rows within a fact table
			// tData is starting id, tData2 is ending id
			Set tFactList = tSQLParams		// DTB891 - Rename for clarity
			New %dsMissingRef
			Set %dsMissingRef = 0
			Set tExtentHasData = 1		// DTB371 - Assume extent has data at the start
			
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2)
			}
			Set tClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeName,.tSC)
			If $$$ISERR(tSC) Quit
			// Use batch mode
			Set tBatch = 1
			
			// DTB371 - If the startId is 0, check to make sure there is actually data in the table!
			If tData=0 {
				Set tSC = $classmethod(tClass,"%GetSourceIds",.tExtentStartId)
				Set:tExtentStartId="" tExtentHasData=0
			}

			If (tExtentHasData) {
				// DTB371 - Only call update facts if the extent actually contains source records
				If $G(tFactList)'="" {
					// DTB891 - Dispatch to %UpdateFactList if the fact list is defined
					// DTB961 - The %UpdateFactsList now can handle the tBatch setting without the caller
					// needing to alter it before the call
					Set tSC = $classmethod(tClass,"%UpdateFactsList",tFactList,tData,tData2,tBatch,0,pTaskGroup)
				}
				Else {
					Set tSC = $classmethod(tClass,"%UpdateFacts",tData,tData2,tBatch,0,pTaskGroup)
				}
			}
			If $$$ISERR(tSC) {
				// JMD1474: ignore
				Set tSC = $$$OK
			}
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2)
			}
			
			// DTB301
			Set inc=$I($$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"missing"),%dsMissingRef)
		}
		ElseIf (tTaskType = "UPDATEFACTSTEMP") {
			// This method's target branch within $$$DeepSeeTempSourceId is identified using
			//  - tData:	CubeIndex
			//  - tData2:	Chunk
			// Individual IDs are stored under the 3rd subscript in a chunked branch
			//  $$$DeepSeeTempSourceId(CubeIndex,Chunk,ID) = $LB("",action)
			// And are queryable using 
			//  SELECT sourceID from %DeepSee.TempSourceId WHERE <restriction>
			
			Set tFactList = tSQLParams		// DTB891 - Rename for clarity
			// update a range of rows within a fact table
			// using source ids in a temp file (global)
			// tData is temp file key, tData2 is chunk
			New %dsMissingRef
			Set tChunkHasData=1
			
			// Synchronize will turn off the batch mode, build uses it (the default)
			Set tBatch = '+tData3
			
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2 _ " ("_$S(tBatch:"build",1:"synchronize")_")")
			}
			Set tClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeName,.tSC)
			If $$$ISERR(tSC) Quit

			// Check to make sure there is actually data in the table!
			// DP-419455 - At least one ID node must exist in the temp sourceID table for this to have any work to do.
			// This can be checked directly without need to return to a query of the source data. 
			Set tChunkStartId = $O($$$DeepSeeTempSourceId(tData,tData2,""))
			Set:tChunkStartId="" tChunkHasData=0

			// Loop over temp file
			Set tDeleteErrorCount = 0
			Set %dsMissingRef = 0
			
			If (tChunkHasData) {
				// DTB371 - Only call update facts if the extent actually contains source records
				Set tTempLocation = $LB(tData,tData2)		// DTB976 - Setup for single insert/update call
				
				// + DP-412844 - Select all IDs marked for delete from the temp table. Since there is no bulk 
				// (Update + Delete) option in the Fact table's library these delete operations must be done 
				// individually.
				Set tDeleteIds = ##class(%SQL.Statement).%ExecDirect(,"SELECT sourceId FROM %DeepSee.TempSourceId WHERE (cubeName = '"_tData_"') AND (chunk = '"_tData2_"') AND (action = 2)")
				While tDeleteIds.%Next() {
					Set tSourceId = tDeleteIds.%GetData(1)
					Set tSC = $classmethod(tClass,"%DeleteFact",tSourceId)
					
					If $$$ISERR(tSC) {
						Set tDeleteErrorCount = tDeleteErrorCount+1
						Set tSC = $$$OK		// DTB300 - This does not halt the task
					}
					Else {
						// DTB976 - If the delete successfully completed, this ID can be removed from
						// this temp list before moving on to the bulk update in %UpdateFacts
						&SQL(DELETE FROM %DeepSee.TempSourceId WHERE (cubeName = :tData) AND (sourceId = :tSourceId))
					}
				}
				If $$$ISERR(tSC) Quit
				// - DP-412844
				
				// DTB976 - Call the update with the $$$DeepSeeTempSourceId information
				If $G(tFactList)'="" {
					Set tSC = $classmethod(tClass,"%UpdateFactsList",tFactList,tTempLocation,,tBatch,0,pTaskGroup)
				}
				Else {
					Set tSC = $classmethod(tClass,"%UpdateFacts",tTempLocation,,tBatch,0,pTaskGroup)
				}
			}
			If $$$ISERR(tSC) {
				// DP-426923 - ignore
				Set tSC = $$$OK
			}
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2)
			}
			
			// DTB300 - Log for reporting
			Set inc=$I($$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"errors"),tDeleteErrorCount)
			Set inc=$I($$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"missing"),%dsMissingRef)

		}
		ElseIf (tTaskType = "BUILDINDICES") {
			Set tFactList = tSQLParams		// DTB891 - Rename for clarity
			// build indices for a range of rows within a fact table
			// tData is starting id, tData2 is ending id
			Set tRangeStartId = tData
			Set tRangeEndId = tData2
			Set tDelta = tRangeEndId - tRangeStartId + 1
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2)
			}

			Set tClass = ##class(%DeepSee.Utils).%GetCubeFactClass(tCubeName,.tSC)
			If $$$ISERR(tSC) Quit
			Set tSC = $classmethod(tClass,"%BuildIndices",tFactList,,,,tRangeStartId,tRangeEndId)		// DTB891 - Use %BuildIndices
			If $$$ISERR(tSC) Quit
  			Set inc=$I($$$DeepSeeTempUpdate($ZU(5),pTaskGroup,"facts"),tDelta)
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2)
			}
		}
		ElseIf (tTaskType = "PRECOMPUTE") {
			// precompute aggregates a range of rows within a fact table
			// tData is starting chunk, tData2 is ending chunk, tData3 is the bucket slot number
			Set tStartChunk = tData
			Set tEndChunk = tData2
			Set tSlotNo = tData3
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("Start " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2)
			}

			Set tClass = ##class(%DeepSee.Utils).%GetCubeFactClass(tCubeName,.tSC)
			If $$$ISERR(tSC) Quit

			// construct process private GLVN to hold results
			// We use a global to avoid <STORE> errors and indirection to avoid contention!
			Set tAggGLVN = "^||DeepSee.Agg."_$ZCRC(tCubeName,7)_"."_tSlotNo
			Kill @tAggGLVN
			Set tSC = $zobjclassmethod(tClass,"%PrecomputeAggregates",tStartChunk,tEndChunk,tAggGLVN,,pTaskGroup)
			If $$$ISERR(tSC) {
				Kill @tAggGLVN
				Quit
			}
			Kill $$$DeepSeeCellsGLVN($$$UPPER(tCubeName),tSlotNo)
			Merge $$$DeepSeeCellsGLVN($$$UPPER(tCubeName),tSlotNo) = @tAggGLVN
			Kill @tAggGLVN
			If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
				Do ..%Log("End " _ tTaskType _ ":" _ tCubeName _ ":" _ tData _ "->" _ tData2)
			}
		}
		ElseIf (tTaskType = "JOININDEX") {
			// execute a "bitflip"
			// Cube,RemoteCube,FactNo,Key
			Set tSC = ##class(%DeepSee.Query.Engine).%CreateJoinIndex(tCubeName, tData, tData2,tData3,tQueryKey)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tTaskType = "COMPUTEKPI") {
			// JMD900
			// compute values for a KPI
			// KPIClass,CacheKey
			Set tSC = $classmethod(tCubeName,"%ComputeKPI",tQueryKey)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tTaskType = "TEST") {
			// Used by %Test method
			Set ^DeepSee.TestAgents($I(^DeepSee.TestAgents)) = $J _ ":" _ tData
			Hang 2
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"WorkMgr encountered unknown tasktype: " _tTaskType)
			Quit
		}
		
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	// DP-405378 - Do not overwrite status coming from the primary business logic. Log the close
	// failure and report the operational status back to the caller.
	Set tCloseSC = ..%CloseTask(pTaskGroup,pParameters)
	If $$$ISERR(tCloseSC) {
		// make note of the error in our task group
		Set:pTaskGroup'="" $$$DeepSeeTaskGroupGLVN(pTaskGroup,"errorCode","onclose") = tCloseSC
		Do ..%Log($System.Status.GetErrorText(tCloseSC))
	}

	$$$dsStopNamedTimer($$$dsCurrentMethod_":"_$G(tTaskType,"none"))		// DTB980
	
	// Drop any Gateway connections in case queries were run against external tables
	do DropAll^%apiGTW()
	
	// log an operational error if it occurred.
	If $$$ISERR(tSC) {
		// make note of the error in our task group
		Set:pTaskGroup'="" $$$DeepSeeTaskGroupGLVN(pTaskGroup,"errorCode") = tSC
		Do ..%Log($System.Status.GetErrorText(tSC))
	}

	Quit tSC
}

///  Log a message to the agent log.
ClassMethod %Log(pMsg As %String)
{
	// Log is a ring buffer of size LOGSIZE
	Set tID = $I($$$DeepSeeAgentLogGLVN)
	Set tLogSize = $G($$$DeepSeeAgentLogGLVN("settings","logSize"),100)
	Set $$$DeepSeeAgentLogGLVN(tID#tLogSize) = $LB(tID,$ZDT($ZTS,3,,3),+$J,+$G(%dsAgentId),+$G(%dsTaskId),pMsg)

	// also log to log file
	Do ##class(%DeepSee.Utils).%WriteToLog("WorkMgr",pMsg)
}

///  Print contents of the (global-based) agent log to the console.
ClassMethod %PrintLog()
{
	If $D($$$DeepSeeAgentLogGLVN)&&($O($$$DeepSeeAgentLogGLVN("settings"),-1)'="") {
		// log is ring buffer; first build list sorted by time
		Set tID = $O($$$DeepSeeAgentLogGLVN(""),1,tItem)
		While (tID'="") {
			Set tLogID = $LG(tItem,1) 
			Set tTime = $LG(tItem,2)
			Set tList(tTime,tID) = tItem
			Set tID = $O($$$DeepSeeAgentLogGLVN(tID),1,tItem)
		}

		// now print out items
		Write "#",?3,"Time",?18,"Agt",?24,"Tsk",?28,"Message",!
		Set n = 0
		Set tTime = $O(tList(""))
		While (tTime'="") {
			Set tID = $O(tList(tTime,""),1,tItem)
			While (tID'="") {
				Set n = n + 1
				Set tAgentId = $LG(tItem,4)
				Set tTaskId = $LG(tItem,5)
				Set:tTaskId=0 tTaskId="-"
				Set tMsg = $LG(tItem,6)
				Write n,?3,$P(tTime," ",2),?17,$J(tAgentId,4),?22,$J(tTaskId,5),?28,tMsg,!
				Set tID = $O(tList(tTime,tID),1,tItem)
			}
			Set tTime = $O(tList(tTime))
		}
	}
	Else {
		Write "No events in log.",!
	}

	// now print out current active tasks & agents
	Do ..%PrintActiveTasks()
	Do ..%PrintPendingTasks()
	Do ..%PrintTaskGroups()
}

///  Print current task groups to the console.
ClassMethod %PrintTaskGroups()
{
	If $D($$$DeepSeeTaskGroupGLVN) {
		Set n = 0
		Set tTaskGroup = $O($$$DeepSeeTaskGroupGLVN(""))
		While (tTaskGroup'="") {
			Write:n>0 !,"Current Task Groups:",!
			Set n = n+1
			Set tCount = +$G($$$DeepSeeTaskGroupGLVN(tTaskGroup,"count"))
			Set tComplete = +$G($$$DeepSeeTaskGroupGLVN(tTaskGroup,"complete"))
			Set tErrors = +$G($$$DeepSeeTaskGroupGLVN(tTaskGroup,"error"))
			Set tOpen = tCount - tComplete
			Write:tCount>0 tTaskGroup,?20,$J($FN(tOpen,",",0),7)," open task(s)",?45,$FN(((tComplete/tCount)*100),",",2),"%"
			If (tErrors) {
				Write ?50,tErrors," errors(s)"
			}
			Write !
			Set tTaskGroup = $O($$$DeepSeeTaskGroupGLVN(tTaskGroup))
		}
	}
}

///  Print list of active tasks out to the console.
ClassMethod %PrintActiveTasks()
{
	/*
	Active Tasks for WorkMgr groups are logged
		$LB( $ZDT($ZTS,3,,3) , $J , pTaskGroup ) _ pParameters
	Where:
		Set tTaskId = $LG(pParameters,1)
		Set tTaskType = $LG(pParameters,2)
		Set tCubeName = $LG(pParameters,3)
		Set tQueryKey = $LG(pParameters,4)
		Set tData = $LG(pParameters,5)
		Set tData2 = $LG(pParameters,6)
		Set tData3 = $LG(pParameters,7)
		Set tSQLParams = $LG(pParameters,8)
	*/
	
	If $D($$$DeepSeeActiveTasksGLVN) {
		Write !,"Tasks actively being worked on:",!
		Write "#",?4,"Tsk",?11,"Job",?15,"Group",?22,"Time",?47,"Type",!
		Set n = 0
		Set tTaskId = $O($$$DeepSeeActiveTasksGLVN(""),1,tDetails)
		While (tTaskId'="") {
			Set n = n + 1
			Set tTime = $P($LG(tDetails,1)," ",2)
			Set tJob = $LG(tDetails,2)
			Set tGroup = $LG(tDetails,3)
			Set tType = $LG(tDetails,5)
			Write n,?3,$J(tTaskId,4),?10,$J(tJob,4),?15,tGroup,?22,tTime,?47,tType,!
			Set tTaskId = $O($$$DeepSeeActiveTasksGLVN(tTaskId),1,tDetails)
		}
	}
}

/// Print list of pending (queued) tasks out to the console.
ClassMethod %PrintPendingTasks()
{
	/*
	Task details for WorkMgr groups are logged
		Set tTaskId = $LG(pParameters,1)
		Set tTaskType = $LG(pParameters,2)
		Set tCubeName = $LG(pParameters,3)
		Set tQueryKey = $LG(pParameters,4)
		Set tData = $LG(pParameters,5)
		Set tData2 = $LG(pParameters,6)
		Set tData3 = $LG(pParameters,7)
		Set tSQLParams = $LG(pParameters,8)
	*/
	If $D($$$DeepSeeTasksGLVN) {
		Set n = 0
		Set tTaskId = $O($$$DeepSeeTasksGLVN(""),1,tDetails)
		While (tTaskId'="") {
			If (n=0) {
				Write !,"Tasks pending in work list:",!
				Write "#",?4,"Type",!
			}
			Set n = n + 1
			Set tType = $LG(tDetails,2)
			Set tCubeName = $LG(tDetails,3)
			Write n,?4,tType,?30,tCubeName,!
			Set tTaskId = $O($$$DeepSeeTasksGLVN(tTaskId),1,tDetails)
		}
	}
}

///  Kill the agent log.
ClassMethod %KillLog(pMsg As %String) As %Status
{
	// DTB300 - Preserve the log settings
	If $D($$$DeepSeeAgentLogGLVN("settings")) {
		Merge tLogSettings = $$$DeepSeeAgentLogGLVN("settings")
	}
	Kill $$$DeepSeeAgentLogGLVN
	Merge $$$DeepSeeAgentLogGLVN("settings") = tLogSettings
	
	Kill ^DeepSee.TaskArchive
	Quit $$$OK
}

///  Diagnostic method.
ClassMethod %RunArchivedTask(pTaskId As %Integer, pVerbose As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Try {
		If '$G($$$DeepSeeAgentLogGLVN("settings","useArchive"),0) {
			Set tSC = $$$ERROR($$$GeneralError,"Task archive not enabled")
			Quit
		}
		
		Set tSC = ..%CreateTaskGroup(.tTaskGroup,0,"RunArchive")

		#; get details
		Set tDetails = $G(^DeepSee.TaskArchive(pTaskId))
		If (tDetails = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No task data found")
			Quit
		}
		
		Set tTaskType = $LG(tDetails,2)
		Set tCubeName = $LG(tDetails,3)
		Set tData = $LG(tDetails,5)

		Write:pVerbose "EXECUTE: ",tTaskType,":",tCubeName,":",tData,!
		Set tSC = ..%ExecuteTask(tTaskGroup,tDetails,1)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do:pVerbose $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// Diagnostic method to dispatch an archived task to a DeepSee background agent. Several tasks can be grouped into a single
/// batch of archived tasks by supplying a <var>pTaskGroup</var>. If <var>pSuppressArchive</var> = 1, the re-execution of an
/// archived task will not get archived.
ClassMethod %QueueArchivedTask(pTaskId As %Integer, pTaskGroup As %String = "", pVerbose As %Boolean = 1, pSuppressArchive As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If '$G($$$DeepSeeAgentLogGLVN("settings","useArchive"),0) {
			Set tSC = $$$ERROR($$$GeneralError,"Task archive not enabled")
			Quit
		}
		If '+pTaskId {
			Set tSC = $$$ERROR($$$GeneralError,"Task ID is required to execute archived task")
			Quit
		}

		#; get details
		Set tDetails = $G(^DeepSee.TaskArchive(pTaskId))
		If (tDetails = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No task data found")
			Quit
		}
		
		If (pTaskGroup="") {
			// DTB - %QueueArchivedTask has been called without a token, a new WorkMgr is needed
			Set tSC = $$$ERROR($$$GeneralError,"%QueueArchivedTask attempted without a task group")
			Quit
		}
		
		Set tTaskGroup = pTaskGroup
		
		Set tTaskType = $LG(tDetails,2)
		Set tCubeName = $LG(tDetails,3)
		Set tData = $LG(tDetails,5)
		/*
		Set pTaskType = $LG(pParameters,1)
		Set pCubeName = $LG(pParameters,2)
		Set pQueryKey = $LG(pParameters,3)
		Set pData = $LG(pParameters,4)
		Set pData2 = $LG(pParameters,5)
		Set pData3 = $LG(pParameters,6)
		Set pSQLParams = $LG(pParameters,7)
		*/
		
		Write:pVerbose "EXECUTE: ",tTaskType,":",tCubeName,":",tData,!
		Set tSC = pWorkMgr.Queue("##class(%DeepSee.WorkMgr).%ExecuteTask",tTaskGroup,tDetails,1)	
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This is a diagnostic utility which will run a group of tasks from the task archive. Siunce the task archive is a ring buffer,
/// <var>pTaskEndId</var> may be set to 0 to indicate that the method should run to the end of the log. By default the method will 
/// re-queue the entire task archive beginning at position #1 for processing by DeepSee background agents. When using background 
/// processing, if <var>pSuppressArchive</var> = 1, then the re-execution of an archived task will not get archived.
/// <br>
/// The method can be switched to execute each task sequentially in the foreground by setting <var>pAsync</var>=0. 
ClassMethod %RunArchivedTaskGroup(pTaskStartId As %Integer = 1, pTaskEndId As %String = 0, pAsync As %Boolean = 1, pSuppressArchive As %Boolean = 1, pWaitTimeout As %Integer = 30, pVerbose As %Boolean = 1) As %Status [ Internal ]
{
	// Method added by DTB302
	If pTaskEndId=0 {
		Set tTaskEndId = $O(^DeepSee.TaskArchive(""),-1)
	}
	Else {
		Set tTaskEndId = pTaskEndId
	}
	Set tTaskEndId = $O(^DeepSee.TaskArchive(tTaskEndId+1),-1)
	
	Set tMaxTaskCount = tTaskEndId-pTaskStartId		// There could be holes in the list of ID's!
	Set tReportDelta = $Select(tMaxTaskCount<10:1,tMaxTaskCount<100:5,1:50)

	Set tSC = $$$OK
	Try {
		If '$G($$$DeepSeeAgentLogGLVN("settings","useArchive"),0) {
			Set tSC = $$$ERROR($$$GeneralError,"Task archive not enabled")
			Quit
		}
		
		// Get the group from first task
		Set tDetails = $G(^DeepSee.TaskArchive(pTaskStartId))
		If (tDetails = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No task data found for archived task "_pTaskStartId)
			Quit
		}
		
		Set tSC = ..%CreateTaskGroup(.tTaskGroup,pAsync,"RunArchiveGroup")
		Write:pVerbose "Task group for archived task execution is " _ tTaskGroup,!
		
		Set tStartTime = $ZH
		
		Set tTaskCount = 0
		Set tTaskId = $O(^DeepSee.TaskArchive(pTaskStartId-1))
		Write:pVerbose ?2,"Begin queueing tasks...",!
		While (tTaskId'="")&&(tTaskId<=tTaskEndId) {
			Set x = $I(tTaskCount)
			
			If pAsync {
				If pVerbose&&'((tTaskCount)#tReportDelta) {
					Write ?2,"Queueing archived task # "_tTaskId,!
				}
				Set tSC = ..%QueueArchivedTask(tTaskId,tTaskGroup)
			}
			Else {
				If pVerbose&&'((tTaskCount)#tReportDelta) {
					Write ?2,"Executing archived task # "_tTaskId,!
				}
				Set tSC =  ..%RunArchivedTask(tTaskId,0)
			}
			
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			Set tTaskId = $O(^DeepSee.TaskArchive(tTaskId))
		}
		
		If pAsync {
			If pVerbose {
				Write "Time to queue " _ tTaskCount _ " tasks: " _ ($ZH-tStartTime) _ "s",!
				Write ?2,"Waiting for task group",!
			}
			
			Set tCompleted = 0
			Set tAttempt = 0
			Set tMaxAttempts=5
			While 'tCompleted&&(tAttempt<tMaxAttempts) {
				Set tSC = ..%WaitForTaskGroup(tTaskGroup,.tCompleted,pWaitTimeout)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				
				If ('tCompleted) {
					Set tAttempt = tAttempt + 1
					Write ?2,"Task Group not completed.",!
				}
			}
			
			If 'tCompleted {
				Set tSC = $$$ERROR($$$GeneralError,$$$FormatText("Task Group not completed after %1 attempts",tMaxAttempts))
				Quit
			}
			Else {
				Write:pVerbose ?2,"Task group complete",!
			}
		}
		
		Write:pVerbose "Elapsed Time: " _ ($ZH-tStartTime)
	}
	Catch ex {
		If tTaskGroup'="" {
			Do ..%KillTasksForGroup(tTaskGroup)
		}
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Write:pVerbose "ERROR: " _ $system.Status.GetOneStatusText(tSC),!
	}

	Quit tSC
}

///  - NOT IMPLEMENTED -
/// There is no longer direct management of agents by this class.
ClassMethod %CountLiveAgents(pPriority = "H", Output pStatus, pCleanDeadAgents = 0) As %Integer [ Internal ]
{
	Set pStatus = $$$NotImplemented
	Quit 0
}

///  - NOT IMPLEMENTED -
/// Agents are always available and created as needed. There is no need to test anymore.
ClassMethod %AgentsAvailable(pPriority = "H", Output pStatus) As %Integer
{
	Set pStatus = $$$NotImplemented
	Quit 1
}

///  Perform simple test of DeepSee WorkMgr.
///  This will kill any pending task.
ClassMethod %Test(pTaskCount = 25, pTimeOut = 0, pClean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill ^DeepSee.TestAgents
		
		Set tTaskCount = pTaskCount

		Write "Create task group: "
		Set tSC = ..%CreateTaskGroup(.tGroupId,1)	
		If $$$ISERR(tSC) {
			Write !,"Error creating task group:",!
			Do $System.Status.DisplayError(tSC)
			Quit
		}
		Write "'",tGroupId,"'",!

		Write "Create tasks"
		For n=1:1:tTaskCount {
			Set tSC = ..%QueueTask(tGroupId, "TEST","","",n*100)
			If $$$ISERR(tSC) Quit
			Write "."
			Hang .1
		}
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Write !
	If $$$ISERR(tSC) {
		Write !,"Error queuing task",!
		Do $System.Status.DisplayError(tSC)
		Write !
		Quit tSC
	}
	Else {
		Write !,"Tasks queued successfully",!
	}

	Set tAttempt = 0
	
Wait
	Write "Waiting for tasks: '",tGroupId,"'"
	Set tSC = ..%WaitForTaskGroup(tGroupId,.tCompleted,pTimeOut)
	If $$$ISERR(tSC) {
		Write !,"Error in WaitForTaskGroup:",!
		Do $System.Status.DisplayError(tSC)
		Quit tSC
	}
	Write !

	If ('tCompleted) {
		Set tAttempt = tAttempt + 1
		Write "Task Group not completed.",!
		Goto:tAttempt<10 Wait
	}

	Write "Task Group completed.",!
	Write "Results: x(task) = JOB:DATA",!
	ZW ^DeepSee.TestAgents

	If (pClean) {
		Write "Kill agents..."
		Do ..%KillAgents()
		Write !
	}
	
	Quit tSC
}

/// Create a new %SYSTEM.WorkMgr instance for use managing this DeepSee task queue.
ClassMethod %InitializeWorkMgr(pQueueName, Output pStatus) As %SYSTEM.WorkMgr
{
	// Method added by DTB923
	Set pStatus = $$$OK
	
	Try {
		If (pQueueName["UPDATEFACTS") ||
			(pQueueName["BUILDINDICES") ||
			(pQueueName["BUILDCUBE") ||
			(pQueueName["SYNCHRONIZE") ||
			(pQueueName["PRECOMPUTE") {
			// Build operations use the build agent cap
			Set tType = "build"
		}
		Else {
			// All remaining operations use the runTime agent cap
			Set tType = "runTime"
		}
		
		Set tAgentCountMax = ##class(%DeepSee.Utils).%GetAgentCount(tType _ "Max")
		Set tAgentCount = ##class(%DeepSee.Utils).%GetAgentCount(tType)
		
		// Do not request more agents than the max active setting
		If (tAgentCountMax && ('tAgentCount || (tAgentCount>tAgentCountMax))) {
			Set tAgentCount = tAgentCountMax
		}
		
		Set tInitializeArgs($I(tInitializeArgs)) = ""									// %New Argument 1
		Set tInitializeArgs($I(tInitializeArgs)) = $S(tAgentCount:tAgentCount,1:"")		// %New Argument 2

		// DTB929 - Check to see if a category maximum exists, add the category name to the arguments if it does
		If +tAgentCountMax {
			Set tInitializeArgs($I(tInitializeArgs)) = $$$dsCategoryName(tType)			// %New Argument 3
		}
		
		Set tWorkMgr = ##class(%SYSTEM.WorkMgr).%New(tInitializeArgs...)
		
		If $IsObject(tWorkMgr) {
			// DTB956 - Move the session information into a local variable that will be passed
			// to the setup and teardown code directly. The tContext array is available for any other
			// environment settings that a worker would need to use to establish a background copy
			// of the calling environment. Code referenced in
			//  ^DeepSee.InitCode
			//  ^DeepSee.CloseCode
			// is run automatically by the relevant %DeepSee.Utils APIs and so these are not passed through
			// the context.
			Set tContext("queueID") = pQueueName
			If $IsObject($G(%session)) {
				Set tContext("session","SessionId") = %session.SessionId
				Set tContext("session","Language") = %session.Language
			}
			
			// DTB956 - Define the callbacks for the setup and teardown of this work environment
			Set pStatus = tWorkMgr.Setup("##class(%DeepSee.WorkMgr).%SetupQueueContext",.tContext)
			If $$$ISERR(pStatus) Quit
			Set pStatus = tWorkMgr.TearDown("##class(%DeepSee.WorkMgr).%TearDownQueueContext",.tContext)
			If $$$ISERR(pStatus) Quit
			Set pStatus = tWorkMgr.Cleanup("##class(%DeepSee.WorkMgr).%CleanupQueueContext",.tContext)
			If $$$ISERR(pStatus) Quit
			
			// Note that there is an active WorkMgr for this work group.
			Set $$$DeepSeeAgentsGLVN("workToken",pQueueName) = ""
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tWorkMgr
}

/// Setup procedure to be run by each %SYSTEM.WorkMgr process as it picks up work from
/// a %DeepSee.WorkMgr queue. All environmental setup should occur here. This will execute
/// the user defined setup code if the call is defined in the ^DeepSee.InitCode global.<br>
/// The <var>pCallingContext</var> is an array to be used as a container for any relevant
/// context established in the calling environment (for example %session information) that
/// needs to be present in the background. 
ClassMethod %SetupQueueContext(ByRef pCallingContext) As %Status [ Internal ]
{
	// Method added by DTB956
	Set tSC = $$$OK
	
	Try {
		// Attempt to run the ^DeepSee.InitCode. This API is a no-op if the global is undefined
		Set tSC = ##class(%DeepSee.Utils).%RunServerInitCode()
		If $$$ISERR(tSC) Quit
		
		// Set CSP session context if it exists
		If $D(pCallingContext("session")) {
			Kill %session
		
			Set %session = ##class(%CSP.Session).%New($G(pCallingContext("session","SessionId")),0)
			If $IsObject($G(%session)) {
				Set %session.Language = $G(pCallingContext("session","Language"))
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit $$$OK
}

/// Tear-down procedure to be run by each %SYSTEM.WorkMgr worker process as it completes all work and 
/// detaches from a %DeepSee.WorkMgr-managed queue. All environmental tear down should occur here. This will execute
/// the user defined tear-down code if the call is defined in the ^DeepSee.CloseCode global.<br>
/// The tear-down will receive the same <var>pCallingContext</var> array as was passed to 
/// <method>%SetupQueueContext</method>.
ClassMethod %TearDownQueueContext(ByRef pCallingContext) As %Status [ Internal ]
{
	// Method added by DTB956
	Set tSC = $$$OK
	
	Try {
		// Attempt to run the ^DeepSee.CloseCode. This API is a no-op if the global is undefined
		Set tSC = ##class(%DeepSee.Utils).%RunServerCloseCode()
		If $$$ISERR(tSC) Quit
		
		// If a CSP session has been initiated for this environment, remove it
		Kill %session
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit $$$OK
}

/// This is the worker method that will be executed as cleanup upon final close of the %SYSTEM.WorkMgr queue. At the
/// time this executes there is no further need for any of the indices and metrics filed under the group label that was generated with
/// the original %SYSTEM.WorkMgr, and on exit there should be no trace of the queueID label in the operational globals.
ClassMethod %CleanupQueueContext(ByRef pCallingContext) As %Status [ Internal ]
{
	// Method added by DP-415779
	Set tSC = $$$OK

	Try {
		Set tTaskGroup = pCallingContext("queueID")
		If $G($$$DeepSeeAgentLogGLVN("settings","logAll"),0) {
			Do ..%Log("Task group complete: "_tTaskGroup_" "_$G(%dsCubeName))
		}
		
		Kill $$$DeepSeeAgentsGLVN("ActiveAgentsCount",tTaskGroup)
		
		Kill $$$DeepSeeTaskGroupGLVN(tTaskGroup)		
		Kill $$$DeepSeeAgentsGLVN("workToken",tTaskGroup)		// Clear the work token container
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
