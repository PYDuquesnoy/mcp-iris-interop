/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Super class for backup tasks.
Class %SYS.Task.BackupSuper [ System = 4 ]
{

Parameter TaskName;

Property Device As %String(MAXLEN = 1024) [ InitialExpression = {##class(%File).NormalizeDirectory("Backup")} ];

Property SaveToTape As %Boolean [ InitialExpression = "0" ];

/// Back up tape device if it is save to tape
Property TapeDevice As %String [ InitialExpression = "47" ];

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "settings" for the task, and then
/// invokes this method to execute the task.<br>
/// In order to execute a real task, override this method in a subclass.
Method OnTask() As %Status
{
#;We must run in %SYS
	d $zu(5,"%SYS")
	Set TaskName = ..#TaskName
	Set jobbackup = 0
	Set quietflag = 1
	#; remove leading whitespace on Device to prevent accidental relative paths
	Set Device = $Case(..SaveToTape,1:..TapeDevice,:$zstrip(..Device,"<W"))
	Set tSC = ##class(Backup.General).StartTask(TaskName, jobbackup, quietflag, Device, ..SaveToTape)
	Quit tSC
}

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Private, ProcedureBlock = 1 ]
{
	If ..SaveToTape = 1,..TapeDevice = "" Quit $$$ERROR($$$MustEnterTapeDevice)
	Quit $$$OK
}

}
