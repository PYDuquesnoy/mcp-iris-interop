/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Task to run an Inventory Scan
Class %SYS.Task.InventoryScan Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "InventoryScan";

/// This method is responsible for executing the task
/// At the scheduled time, the Task Manager
/// - creates an instance of this object,
/// - Sets any property values using the stored "Settings" for the task,
/// - and invokes this method to execute the task.
Method OnTask() As %Status
{
#;We must run in %SYS
	d $zu(5,"%SYS")
	Set scanName = "Inventory Scan: " _ $ZV
	Set scan = ##class(Inventory.Scanner).RunScan(scanName)
	Set sc = scan.%Save()
	Quit sc
}

}
