/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides an interface to the work queue manager code that allows work to be distributed to multiple
/// processes in order to improve performance. To use this you construct an instance of the work queue manager, then divide the work
/// up into units that can be processed independently and queue each unit of work, and finally
/// wait for the work to be completed. The units of work can output to the current device which will be buffered up
/// and output to the main job's device when that unit of work is signalled as complete. Also all units of work by
/// default are expected to return a <class>%Status</class> value so it can indicate errors, these are
/// returned by the <method>Sync</method> method (formerly <method>WaitForComplete</method>) or the <method>WaitOne</method>
/// or the <method>Wait</method>.<p> 
/// A typical calling sequence is:
/// <example>
/// Set queue=$system.WorkMgr.%New() If queue="" ; Report Error, can check %objlasterror for %Status code
/// For i=1:1:100 {
/// 	Set sc=queue.Queue("##class(MyClass).ClassMethod",i) If $$$ISERR(sc) ; Report Error
/// }
/// Set sc=queue.Sync() If $$$ISERR(sc) ; Report Error
/// </example>
/// The call to create a new WQM instance requests worker jobs from this category's pool attach to the work group you are
/// creating, if there are not enough worker jobs in the pool and the pool is not at the 'MaxActiveWorkers' limit
/// then the framework will start additional workers automatically. The number of worker jobs we start is determined by
/// the work queue manager based on current machine load and characteristics of the CPU the machine is running on.
/// Every work group is guaranteed at least one worker process to be assigned as soon as a unit of work is queued. Additional
/// workers requested for this group will be allocated from the worker pool if there are workers not already processing work
/// units from other groups. These additional workers are allocated on a first come first serve basis.
/// If <var>numberjobs</var>=0 is passed in on the %New call
/// we will not use any workers jobs at all and will do all the processing in the current job in the <method>Sync</method> method
/// (formerly <method>WaitForComplete</method>) call.<p>
/// Call <method>Queue</method> to queue a unit of work to be run, this takes either a class method
/// call, or a '$$func^rtn' reference and then any arguments you need to pass to this function. We support passing arrays
/// here using the standard '.array' syntax although changes in the array by the work unit are not returned to the caller.
/// As soon as the first <method>Queue</method> is called a worker will start processing this item of work. It is important to make
/// sure that all the units of work are totally independent and they do not rely on other work units. You must not
/// rely on the order in which the units of work are processed. If the units may be changing a common global you
/// will need to add locking to ensure one worker can not change a global while another worker is in the middle of
/// reading this global. When a unit of work is queued the current security context is stored so the work
/// unit will run inside the current security context. Note that the worker jobs are started by the Super Server
/// and so will run as the operating system user that the Super Server process is setup to use, this may be different
/// to your current logged in operating system user.<p>
/// Finally call <method>Sync</method> to wait for all the units of work to be complete, display any
/// output each unit produced and report any errors reported from the work units.
/// Instead of waiting for all work units to complete with the <method>Sync</method> you can obtain notification of each completion
/// using the <method>WaitOne</method> interface which is an iterator over the work completion events. Another mechanism to run code
/// when each work unit is completed is the <method>QueueCallback</method> method.<p>
/// Work units may write to the public variable <var>%result</var> which will be relayed to the parent process in either the
/// <method>WaitOne</method> call or in the callback function from the <method>QueueCallback</method>.
/// Worker jobs are owned by the parent process while they are performing work in this group, so when the parent exits
/// the worker jobs will be released immediately. When the object returned by %New is destroyed this will remove all work associated
/// with this group automatically, and release any workers.<p>
/// The work queued should not perform exclusive kills or argumentless unlocks as this will interfere with the framework.
/// Use of process private globals are only helpful within a chunk of work and not across chunks as different chunks of work are processed
/// by different workers in different jobs.
/// The size of each chunk should be on the order of thousands of lines of ObjectScript code to ensure the overhead of the framework is
/// not a significant factor, also rather than a few very large chunks (e.g. 4 big chunks) if possible it is better
/// to have a fairly large number (100 say) of chunks as this allows us to scale with CPU cores. Worker jobs once started
/// will remain until they time out given a long enough period of inactivity as these jobs are shared among all work entered
/// into the work queue manager in the same 'category'.<p>
/// The third argument to <method>%New</method> is the  <var>category</var> which specifies which work queue pool to allocate
/// worker jobs from. These categories are independent of each other so for example 'SQL' work is allocated from a different
/// pool to 'Default' work and the load placed on the system from each of the categories can be tuned.
Class %SYSTEM.WorkMgr Extends AbstractWorkMgr
{

/// Queues a specific unit of work, you pass the entry point to call in 'work' argument. This can be either '##class(Classname).ClassMethod'
/// or '$$entry^rtn' and it is expected to return a %Status code on completion. To call a function
/// that does not return any value on completion then prepend the class syntax with '=' e.g. '=##class(Classname).ClassMethod'
/// or to call a function do not include the '$$' e.g. 'entry^rtn'.
/// The item being called may also throw exceptions in order to indicate an error happened which is trapped and converted
/// to a %Status value to be returned in the parent process. You can also pass additional
/// arguments including arrays by reference. Note that the size of the data passed in these arguments should be kept
/// relatively small, if there is a large amount of information that needs to be passed then put this in a global.
/// The security context of the caller is recorded when this function is called and is used when the work is executed.
/// Output the work unit makes to the current device will be trapped and relayed to the parent process after this work unit
/// has complted and when the parent process is waiting for work to be completed. If a work unit wishes to flush output before
/// the work unit has completed then then call 'Do $system.WorkMgr.Flush()'
Method Queue(work As %String, args... As %String) As %Status
{
	Merge group=i%group
	Set sc=$$realQueue^%SYS.WorkQueueMgr(.group,,.work,,.args)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Similar to <method>Queue</method> except you can also pass in a 'callback' which is a function or class method that
/// is called in the parent process when this unit of work is complete. This function is called with the same arguments
/// the original 'work' is called with so it can tell which unit of work is complete. Also the callback function can access
/// the '%job' public variable which is the $job of the process which really did the work, the '%status' public variable
/// which is the %Status return code from the work unit this is the callback for and '%workqueue' public variable which
/// is the oref of the work queue instance. Any error returned by the work unit will by default be added to the <method>Sync</method>
/// return %Status, but the callback may alter the the work units %Status by modifying the public variable '%status'. For example
/// if the callback detects a specific error %Status from the work unit and does a 'Set %status=$$$OK' it will mark
/// this error as handled and no error %Status will be added to the return from <method>Sync</method>.
/// If using the <method>Wait</method> to wait for the work to be completed the callback can signal that it should
/// return to the caller rather than waiting for more events by setting the public variable '%exit' to 1.
Method QueueCallback(work As %String, callback As %String, args... As %String) As %Status
{
	Merge group=i%group
	Set sc=$$realQueue^%SYS.WorkQueueMgr(.group,,.work,.callback,.args)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Internal method, not for customer use.
/// <var>total</var> is an array of argument lists so we can queue multiple entries in one call
Method QueueLocalEntryMulti(rtnidx As %Binary, func As %String, ByRef total As %String) As %Status [ Internal ]
{
	Merge group=i%group
	Set sc=$$realQueue^%SYS.WorkQueueMgr(.group,-1,":"_$listbuild($piece(func,":"),rtnidx,$piece(func,":",2)),,.total)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Internal method, not for customer use.
/// <var>total</var> is an array of argument lists so we can queue multiple entries in one call
Method QueueLocalEntryMultiFunc(ByRef total As %String) As %Status [ Internal ]
{
	Merge group=i%group
	Set sc=$$realQueue^%SYS.WorkQueueMgr(.group,-2,,,.total)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Pause any work in this work queue, this stops any workers from picking up additional items from
/// this queue, but leaves the work itself so you can call <method>Resume</method> at a later point.
/// When no <var>timeout</var> is passed this will return immediately so there could still be work
/// in progress from one of the work units that was being process at the time this function was called.
/// If you pass in a non-null <var>timeout</var> it will wait
/// for up to this timeout value in seconds for work currently in progress to finish. 
/// If after the timeout the work
/// in progress has exited it will set <var>completed</var>=1 else this will be 0.
Method Pause(timeout As %Integer, ByRef completed As %Boolean = 0) As %Status
{
	RETURN $$PauseGroup^%SYS.WorkQueueMgr(i%group,.timeout,.completed)
}

/// Deprecated method, does not do anything.
Method Free() As %Status [ Deprecated, Internal ]
{
	RETURN $$$OK
}

/// Resume any work in this work queue which was paused with a call to <method>Pause</method>.
Method Resume() As %Status
{
	Merge group=i%group
	Set sc=$$ResumeGroup^%SYS.WorkQueueMgr(.group)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Deprecated method
ClassMethod SignalAll(work As %String) As %Status [ Deprecated, Internal ]
{
	RETURN $$$ERROR($$$MethodNotImplemented,"%SYSTEM.WorkMgr:SignalAll")
}

/// Deprecated method
ClassMethod StopWorkers(timeout As %Integer = 5) As %Status [ Deprecated, Internal ]
{
	RETURN $$$OK
}

/// Return the number of worker jobs that we will request for this group. We request workers as units of work
/// are queued, the first worker is requested when the first unit of work is queued. Once we have requested
/// this number of workers we will not request any more. Note that after a worker is requested it may not be
/// cause any worker to attach to this queue if they are all busy doing other work.
/// If the group is detached it will return -1.
Method NumberWorkers() As %Integer
{
	RETURN $$NumWorkerJobs^%SYS.WorkQueueMgr(i%group)
}

/// Called from a worker job to flush any output produced so far to the parent process.
/// Without this all output from a worker job is buffered until this unit of work is complete and only
/// then is it displayed in the parent process.
ClassMethod Flush() As %Status
{
	RETURN $$Flush^%SYS.WorkQueueMgr()
}

/// Return the default number of worker jobs we will use if no specific number is specified
ClassMethod DefaultNumWorkers(category = "Default") As %Integer
{
	RETURN $$calcJobs^%SYS.WorkQueueMgr(,,category)
}

/// Returns true/false based on if the current process is a worker job or not.
ClassMethod IsWorkerJob() As %Boolean
{
	RETURN $$$IsISCWorker
}

/// Detach this oref from the work queue and set <var>token</var> which you can use in another process (or in this process if wanted)
/// to call <method>Attach</method>. The <var>timeout</var> is how long in seconds we will keep information about this work queue in the
/// system, so if you do not Attach to this within this period of time we will remove all information about this queue and any
/// subsequent call to <method>Attach</method> will fail.
Method Detach(ByRef token As %String, timeout As %Integer = 86400) As %Status
{
	If $classname()'="%SYSTEM.WorkMgr" RETURN $$$ERROR($$$GeneralError,"Unable to detach any work queue other than %SYSTEM.WorkMgr, '"_$classname()_"'")
	
	Set data=$lb(i%suppressoutput,i%DeleteTimeout)
	Merge group=i%group
	RETURN $$DetachGroup^%SYS.WorkQueueMgr(.group,timeout,.token,data)
}

/// If you have called <method>Detach</method> on a work queue and have the associated token you can pass this into this class method
/// and assuming the work queue still exists it will create an instance of the work queue manager associated this this queue.
/// If it fails then it will return $$$NULLOREF and set <var>sc</var> with the error %Status value.
ClassMethod Attach(token, ByRef sc As %Status) As WorkMgr
{
	Set sc=$$AttachGroup^%SYS.WorkQueueMgr(token,.group,.numworkers,.data)
	If $$$ISERR(sc) RETURN $$$NULLOREF
	Set oref=$zobjnew($classname())
	Set oref.NumWorkers=numworkers
	Merge oref.group=group
	Set oref.suppressoutput=$lg(data),oref.DeleteTimeout=$lg(data,2)
	RETURN oref
}

}
