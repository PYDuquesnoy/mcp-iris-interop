/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syJrninc

Class %SYS.Task.SwitchJournal Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "SwitchJournal";

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "settings" for the task, and then
/// invokes this method to execute the task.<br>
Method OnTask() As %Status
{
#;We must run in %SYS
	d $zu(5,"%SYS")
	f i=1:1:10 s rc=$$INT^JRNSWTCH(,,.err,,,,,$$$ERRORCODE($$$JRNSWREASONTASKMGR)) q:rc  h 10
	i rc q $$$OK
	#; ^JRNSWTCH may return a converted status code, strip this part off
	i $p(err,":")[("#"_$$$ERRORCODE($$$JournalingSwitchError)),$l(err,":")>2 s err=$p(err,":",3,$l(err,":"))
	q $$$ERROR($$$JournalingSwitchError,err)
}

}
