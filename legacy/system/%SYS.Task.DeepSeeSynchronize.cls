/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.Task.DeepSeeSynchronize Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "Cube Manager Synch";

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "settings" for the task, and then
/// invokes this method to execute the task.<br>
/// In order to execute a real task, override this method in a subclass.
Method OnTask() As %Status
{
	// All of the intelligence will be in SynchronizeGroup
	Set tSC = $$$OK
	try {
		Set tRegistry = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1)
	 	If $$$ISERR(tSC) Quit
	 	
	 	Set tGroupIndex = ""
	 	For ii=1:1:tRegistry.Groups.Count() {
		 	Set tGroup = tRegistry.Groups.GetNext(.tGroupIndex)
		 	// DTB912 - Verify the update plan dictates a synchronize
		 	If (tGroup.UpdatePlan["Synch") {
			 	If tRegistry.SerialUpdates {
			 		Do ##class(%DeepSee.CubeManager.RegistryMapGroup).SynchronizeGroup(tGroupIndex,0)
			 	} Else {
				 	Job ##class(%DeepSee.CubeManager.RegistryMapGroup).SynchronizeGroup(tGroupIndex,0)
			 	}
		 	}
	 	}
	}
	catch (ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do ##class(%DeepSee.Utils).%WriteToLog("Task.Synch",$system.Status.GetErrorText(tSC))
	}
	Quit $$$OK
}

/// This method will make sure the task is registered with the 
/// Task Manager to run on the schedule defined by the arguments. <br><br>
/// If there is currently no task scheduled, this will create one, otherwise
/// it will modify any pre-existing task. The default settings will run the 
/// synch task every 60 minutes.
ClassMethod Schedule(pSuspend = 0, pDailyFrequency = 1, pDailyFrequencyTime = 0, pDailyIncrement = 60, pStartTime = 0, pEndTime = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFullName = ..#TaskName _ " - " _ $NAMESPACE
		Set tTaskID = ##class(%SYS.Task).FindId(tFullName)
		If tTaskID = "" {
			// Task is not present, need to create one
			Set tTask = ##class(%SYS.Task).%New()
			Set tTask.Name = tFullName
			Set tTask.NameSpace = $NAMESPACE
			// DTB006 - Make this task work on Any mirror member
			Set tTask.MirrorStatus = 3
		} Else {
			// Task has already been defined, save it with the current schedule
			Set tTask = ##class(%SYS.Task).%OpenId(tTaskID,,.tSC)
		}
		
		If (tTask.TaskClass="%DeepSee.CubeManager.Task.Synch") {
			// The current task was created by the [license consuming] task definitions
			// in the %DeepSee.CubeManager.Task package. This will now get switched to the
			// definition in the %SYS.Task package. In this event, log that the switch has 
			Do ##class(%DeepSee.Utils).%WriteToLog("Task.Synch",$$$Text("Changing to license-exempt synchronize task"))
		}
		
		If '$IsObject(tTask) {
			// DTB433 - If the task is not open at this point, try to figure out the error and return it
			If $$$ISOK(tSC) {
				Set tSC = %objlasterror
			}
			Quit
		}
		
		Set tTask.TaskClass = "%SYS.Task.DeepSeeSynchronize"
		Set tTask.RunAsUser = "_SYSTEM"
		Set tTask.Type = 0
		Set tTask.Description = "Synchronize DeepSee Cubes according to the Cube Registry schedule"
		
		// Synch runs at least once every day
		Set tTask.TimePeriod = 0			
		Set tTask.TimePeriodEvery = 1   	
		Set tTask.TimePeriodDay = ""
		
		// Set the specifics by arguments passed in via the arguments
		Set tTask.DailyFrequency = pDailyFrequency
		Set tTask.DailyFrequencyTime = pDailyFrequencyTime
		Set tTask.DailyIncrement = pDailyIncrement
		Set tTask.DailyStartTime = pStartTime
		Set tTask.DailyEndTime = pEndTime
		
		// The task should be operational immediately. If the task is scheduled only once a day, then
		// make sure the start time is in the future.
		If 'tTask.DailyFrequency && (pStartTime < $P($H,",",2)) {
			Set tSC = tTask.StartDateSet(+$h + 1)
		} Else {
			Set tSC = tTask.StartDateSet(+$h)
		}
	
		If $$$ISERR(tSC) Quit
		
		Set tSC = tTask.%Save()
		If $$$ISERR(tSC) Quit
		
		If pSuspend {
			Set tSC = tTask.Suspend(tTask.%Id())
		} Else {
			Set tSC = tTask.Resume(tTask.%Id())
		}		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Do ##class(%DeepSee.Utils).%WriteToLog("Task.Synch",$system.Status.GetErrorText(tSC))
	}

	Quit tSC
}

}
