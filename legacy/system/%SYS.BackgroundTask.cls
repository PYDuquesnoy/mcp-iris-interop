/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syBackgroundTask, %sySystem, %syPrompt)

/// This class implements a framework for providing administrators with status and control
/// of long-running tasks/utilities/operations that set to run in the background.  These
/// are typically (but not necessarily) tasks that are started interactively, but run in
/// the background because they may run for a long time (e.g. some database management
/// utilities).  Note that this framework is separate from the "Task Manager" frameword
/// which can be used to schedule activity.  
/// <p>
/// There are subclasses for each type of operation that uses this infrastructure and 
/// objects of those subclasses represent instances that are running or have run since
/// the system started up.
/// <p>
/// To use this framework for progress and control of a background task, you simply
/// open or query objects the objects through this class or the relevant subclass.
/// The properties represent a snapshot of the state and progress of the task.
/// You can periodically check for changes by rerunning the query or reloading the object
/// via standard object interfaces <METHOD>%OpenId</METHOD> and <METHOD>%Reload</METHOD>.
/// <p>
/// <PROPERTY>RunningState</PROPERTY> contains information about whether the task is
/// running or not (as of the time the object was last loaded or queried).
/// Progress information may be available via <PROPERTY>ProgressCurrent</PROPERTY>,
/// <PROPERTY>ProgressTotal</PROPERTY> and <PROPERTY>ProgressUnits</PROPERTY>.  When complete,
/// the %Status is available in <PROPERY>FinalStatus</PROPERTY>.  Subclasses may expose
/// other properties that are germain to that particular type of operation.
/// <p>
/// <METHOD>Pause</METHOD>, <METHOD>Resume</METHOD>, and <METHOD>Cancel</METHOD> are enabled
/// for some subclasses
/// <p>
/// Users should not modify properties or save these objects.
/// <p>
/// To start a job running the task in the background, you can use class method 
/// <METHOD>Start</METHOD> in the desired subclass.  The arguments are unique to each
/// subclass.  <METHOD>Start</METHOD> returns an oref to use for monitor and control.
Class %SYS.BackgroundTask Extends %Persistent [ Abstract ]
{

/// Start time of run
Property StartTime As %TimeStamp [ ReadOnly ];

/// A text string to display as the type of background task as defined by its subclass. 
Property DisplayType As %String [ Calculated, SqlComputeCode = { set {*} = $list($classmethod({Class},"GetDisplayInfo"),1) }, SqlComputed ];

/// The subclass name of the task; accessible via SQL where oref.%ClassName(1) is not be available.
Property Class As %String [ Calculated, SqlComputeCode = { new mstc if ##class(%SYS.BackgroundTask).%OnDetermineClass($$$oidCompose({ID},"%SYS.BackgroundTask"),.mstc) set {*}=mstc }, SqlComputed ];

/// Namespace in which the task is run. 
Property Namespace As %String [ ReadOnly ];

/// Status code when finished
Property FinalStatus As %Status [ ReadOnly ];

/// PID of job performing the work, available once the "Running" state has been entered.
Property PID As %String [ ReadOnly ];

/// Request to the running task.  1 is request to pause. 2 is request to cancel.
Property Request As %Integer [ Calculated, SqlComputeCode = { set {*}=+$listget({ExternalState},2) }, SqlComputed ];

/// Information about whether the task is running or not. 
/// Values are constants, defined for convenience in %syBackgroundTask.inc
/// <li>"Starting" ($$$BGTaskStarting) - Object has been created but has not started working yet.
/// <li>"Running" ($$$BGTaskRunning) - Task is running
/// <li>"Done"  ($$$BGTaskDone) - Task has completed successfully
/// <li>"Error"  ($$$BGTaskError) - Task has returned an error - see <PROPERTY>FinalStatus</PROPERTY>
/// <li>"Paused" ($$$BGTaskPaused) - Task has been pasued
/// <li>"Cancelled" ($$$BGTaskCancelled) - Task has been cancelled
/// <li>"Exited" ($$$BGTaskExited) - Task exited unexpectedly and did not complete normally
Property RunningState As %String [ Calculated, SqlComputeCode = { set {*}=$listget({ExternalState},1) }, SqlComputed ];

/// The current amount of progress made.  To be interpreted, along with <PROPERTY>ProgressTotal</PROPERTY>
/// and <PROPERTY>ProgressUnits</PROPERTY> as follows:
/// <li>non-zero total and non-null units: current and total values are to be displayed with the unit string.  
/// <li>non-zero total and null units: current / total is to be displayed as a percentage.  
/// <li>zero total, non-zero current, and non-null units: current is displayed with the unit string (without reference to the total). 
/// <li>otherwise numeric progress not available.
Property ProgressCurrent As %Numeric [ Calculated, SqlComputeCode = { set {*}=+$listget({ExternalState},3) }, SqlComputed ];

/// The total amount of progress that must be made to complete.  This value may
/// change while running as more accurate estimates become available.
/// See <PROPERTY>ProgressCurrent</PROPERTY> for more detail.
Property ProgressTotal As %Numeric [ Calculated, SqlComputeCode = { set {*}=+$listget({ExternalState},4) }, SqlComputed ];

/// The units in which progress is measured.  Used to display progress to the 
/// user.  Null is allowed, treating progress as dimensionless.
/// See <PROPERTY>ProgressCurrent</PROPERTY> for more details.
Property ProgressUnits As %String [ Calculated, SqlComputeCode = { set {*}=$listget({ExternalState},5) }, SqlComputed ];

/// Internal progress details returned from subclasses in <METHOD>GetProgress</METHOD>.
/// Subclasses may expose calculated properties derived from this value.
Property ProgressDetails As %String [ Calculated, Internal, SqlComputeCode = { set {*}=$listget({ExternalState},6) }, SqlComputed ];

/// True if the <PROPERTY>RunningState</PROPERTY> is one that will not progress
/// any further.  Used by monitoring interfaces to determine whether monitoring
/// should continue.
Property HasEnded As %Boolean [ Calculated, SqlComputeCode = { s {*}=$case({RunningState},$$$BGTaskDone:1,$$$BGTaskError:1,$$$BGTaskCancelled:1,$$$BGTaskExited:1,:0) }, SqlComputed ];

/// True if pause is allowed for this task and the state (as of load time)
/// is such that it can be paused.  Used by user interface code to determine 
/// whether to enable a "pause" control.
Property PauseIsAvailable As %Integer [ Calculated, SqlComputeCode = { s {*}=$select('..#PAUSEDISPOSITION:0,{Request}:0,{RunningState}'=$$$BGTaskRunning:0,1:1) }, SqlComputed ];

/// True if cancel is allowed for this task and the state (as of load time)
/// is such that it can be paused.  Used by user interface code to determine 
/// whether to enable a "cancel" control. 
Property CancelIsAvailable As %Integer [ Calculated, SqlComputeCode = { s {*}=$select('..#CANCELDISPOSITION:0,{Request}=$$$BGTaskReqCancel:0,{RunningState}=$$$BGTaskRunning:1,{RunningState}=$$$BGTaskPaused:1,1:0) }, SqlComputed ];

/// True if pause is allowed and the utility is paused.  Used by user 
/// interface code to determine whether to enable a "resume" control. 
Property ResumeIsAvailable As %Integer [ Calculated, SqlComputeCode = { s {*}=$select('..#PAUSEDISPOSITION:0,{Request}'=$$$BGTaskReqPause:0,{RunningState}=$$$BGTaskRunning:1,{RunningState}=$$$BGTaskPaused:1,1:0) }, SqlComputed ];

/// Index used to access shared memory structure
Property MemIdx As %Integer [ Internal, Private, Required ];

/// Version used to access shared memory structure
Property Version As %Integer [ Internal, Private, Required ];

/// Job number of process with the memory reservation 
Property JobNum As %Integer [ Internal, Private ];

/// JobID of process with the memory reservation 
Property JobID As %Integer [ Internal, Private ];

/// $LISTBUILD string containing any information used to derive the state of this object that
/// does not come from the storage of the object itself.  Such state information is loaded into
/// this transient property once each time the object is loaded or queried.  The exposed
/// properties for such state information are Calculated and derive their values from this property.
Property ExternalState As %List [ Internal, Private, SqlComputeCode = { new rst,o set {*}={ExternalStateStored},rst=$listget({ExternalStateStored},1) if (rst=$$$BGTaskStarting)||(rst=$$$BGTaskRunning) { set o=##class(%SYS.BackgroundTask).%OpenId({ID}) set:o {*}=o.GetExternalState({ExternalStateStored}) } }, SqlComputed, Transient ];

/// Last value of <PROPERTY>ExternalState</PROPERTY>, stored with the object
Property ExternalStateStored As %String(MAXLEN = 30000) [ Internal, Private ];

/// Starts this task in the background and returns on oref for monitoring and control.
/// Returns null on error, with error status available in %objlasterror.
/// The meaning of the arguments are specific to each subclass.
ClassMethod Start(args...) As %ObjectHandle [ Final ]
{
	try {
		set this=..Register(args...)
		return:'$isobject(this) ""
		do job
		return:$$$ISERR(this.WaitForRunning()) ""
	} catch err {
	 	set %objlasterror=err.AsStatus()
		return ""
	}
	return this
job
	#;We want to pass the symbol table so the child has the 'args...' array.
	#;Stack a new frame as we don't really want to the child having other variables.
	new
	merge %BackgroundTaskArgs=args
	job ##class(%SYS.BackgroundTask).Child(this.%Id()):(:1):10
	if '$test { $$$ThrowStatus($$$ERROR($$$BGTaskJobStartFailed)) }
}

/// Creates the object and saves it marked as in "Starting" state. 
/// The caller can then call <METHOD>Run</METHOD> directly or pass the
/// object id to another (background) process to open and then call <METHOD>Run</METHOD>.
/// In the latter case, see documentation for <METHOD>WaitForRunning</METHOD>
/// for important information about coordinating with the other process.
/// <p>
/// Returns null on error, with error status available in %objlasterror.
ClassMethod Register(args...) As %ObjectHandle [ Final, Internal ]
{
	try {
		set this=..%New()
		return:'$isobject(this)
		set sc=this.RegisterSub(args...)
		#; %objlasterror is already set up for the caller when the error was generated
		return:$$$ISERR(sc) ""
		return this
	} catch err {
		set %objlasterror=err.AsStatus()
		return ""
	}
}

/// Marks the task as "Running", executes the code in this process
/// and saves the return status as <PROPERTY>FinalStatus</PROPERTY>.   If this
/// method is called from a process other than the one that created the object
/// and the creating process gave up waiting before this method was called
/// (e.g. it closed the object, or timed out in <METHOD>WaitForRunning</METHOD>),
/// then this method returns an error, $$BGTaskNotRunnable.
/// <p>
/// The arguments passed to this method must be identical to those passed to
/// <METHOD>Register</METHOD>.
Method Run(args...) As %Status [ Final, Internal ]
{
	try {
		set sc=$$$OK
		$$$THROWONERROR(sd,..%LockId(..%Id()))
		set locked=1
		if '$system.BGUtil.ProcessStart(..MemIdx,..Version) {
			#;Either the memidx/version are somehow wrong, the memory 
			#;got marked as freed before we got here, or we were already
			#;running a different task.
			set sc=$$$ERROR($$$BGTaskNotRunnable)
			quit
		}
		set started=1
		#;It's important that PID can't change, but that's ensured by
		#;the call to ProcessStart() above.  That can only succeed
		#;for one job so we can't get here twice for the same object.
		set i%PID=+$job
		set ..JobNum=$zu(61)
		set ..JobID=$zu(61,30,$zu(61))
		do ..SetRunningState($$$BGTaskRunning)
		$$$THROWONERROR(sc,..%Save())		
	} catch err {
		#;Free the memory
		do:$get(started) $system.BGUtil.ProcessEnd()
		$$$SevereMsg("%SYS.BackgroundTask: failed during initialization of Running state - "_err.DisplayString())
		set sc=err.AsStatus()
	}
	if $get(locked) { do ..%UnlockId(..%Id()) }
	return:$$$ISERR(sc) sc
	try {
		$$$THROWONERROR(sc,..OnRunning(args...))
		$$$THROWONERROR(sc,..%Save())
		$$$THROWONERROR(sc,..Execute(args...))
	} catch err {
		set sc=err.AsStatus()		
	}
	do ..End(sc)
	return sc
}

/// To be used when the job calling <METHOD>Register</METHOD> will rely on a different
/// main job (typically, but not necessarily, a child) to perform the work.  After passing
/// the object ID to another job, call this method to wait for that job to call 
/// <METHOD>Run</METHOD>.  If this method times out, the object is deleted.
/// <p>
/// The caller can use the return value to positively report success or failure of
/// starting the task to the user.  Upon success, the job that runs the task has control
/// and status can be tracked through this object.  The object is reloaded as part of this
/// method to reflect that latest state.  Upon return status code $$$BGTaskStartTimeout, 
/// the utility object is deleted, the main job is sure to not be running this task, and 
/// the caller should close this object.
/// <p>
/// Note that calling this method is not strictly required.  The main job can begin
/// running before this method is called.  If the process creating the object
/// does not call this method however, it must ensure that it keeps the object open long
/// enough for the main job to start and call <METHOD>Run</METHOD>.  If the caller
/// closes the object beforehand, it will be automatically cleaned and if the main job
/// eventually calls <METHOD>Run</METHOD>, it will get an error.
Method WaitForRunning(timeout As %Integer = 10) As %Status [ Final, Internal ]
{
	try {
		set i=0,waitintv=.1
		do {
			if '$listget($system.BGUtil.GetInfo(..MemIdx,..Version),$$$BGUtilGetInfoNew) {
				$$$THROWONERROR(sc,..%Reload())
				return $$$OK
			}
			hang .1
			set i=i+(i*waitintv)
		} while (i<timeout)
		$$$THROWONERROR(sc,..%LockId(..%Id()))
		set locked=1
		#; third argument means only free if it is still marked new
		if $system.BGUtil.FreeMemory(..MemIdx,..Version,1) {
			set sc=..%DeleteId(..%Id())
			if $$$ISERR(sc) {
				$$$WarnMsg("%SYS.BackgroundTask: failed to delete object after WaitForRunning timeout, "_$system.Status.GetErrorText(sc))
			}
			set sc=$$$ERROR($$$BGTaskStartTimeout)
		} else {
			#; FreeMemory() failed because the handoff already occurred, 
			$$$THROWONERROR(sc,..%Reload())
			set sc=$$$OK
		}
	} catch err {}
	if $get(locked) { do ..%UnlockId(..%Id()) }
	return:$get(err) err.AsStatus()
	return sc
}

/// Request cancellation.
Method Cancel() As %Status [ Final ]
{
	#; stub will escalate and call back to method Request()
	return ..Request($$$BGTaskReqCancel)
}

/// Request pause.
Method Pause() As %Status [ Final ]
{
	#; stub will escalate and call back to method Request()
	return ..Request($$$BGTaskReqPause)
}

/// Request to resume from pause.
Method Resume() As %Status [ Final ]
{
	#; stub will escalate and call back to method Request()
	return ..Request($$$BGTaskReqResume)
}

/// Subclasses must override this method.  This method is called by the process
/// calling <METHOD>Run</METHOD> to perform the real work.  The return from this
/// method is recorded as <PROPERTY>FinalStatus</PROPERTY>.
/// <p>
/// <b>Overview: Running your code via the %SYS.BackgroundTask framework</b>
/// <p>
/// This class provides infrastructure to run your long-running tasks in the background,
/// with status, progress and administrative control available to the operator.  You
/// create a subclass that specifies certain behaviors, including the rules by which it
/// will display progress and respond to pause and cancel requests.
/// <p>
/// Progress can be reported by periodically posting updates using
/// $system.BGUtil.PostProgress().  Progress can alternatively be calculated (perhaps
/// via a pre-existing mechanism) by overriding the <METHOD>GetProgress</METHOD> callback.
/// You can even use a combination of the two: posting updates with $system.BGUtil.PostProgress()
/// and futher refining them for presentation in the callback.
/// If no progress is reported by any of these mechanisms, the progress field will simply be
/// omitted from the status display.
/// <p>
/// You choose whether to enable the pause and/or cancel control.  You can allow 
/// pause and cancel actions to directly suspend or terminate the job, or you can
/// choose to poll for Pause and Cancel request codes as return values from 
/// $system.BGUtil.PostProgress and/or $system.BGUtil.CheckRequest calls.
/// <p>
/// You may define properties in the subclass to expose more details, such as the 
/// arguments passed by the user or additional progress-related details.  This is
/// discussed further below.
/// <p>
/// <b>More info on using $system.BGUTil methods</b>
/// <p>
/// During execution of the your code, you can call $system methods of the
/// <CLASS>%SYSTEM.BGUtil</CLASS>, namely PostProgress() and CheckRequest().  
/// If your subclass is defined to poll for pause and/or cancel, PostProgress()
/// does so.  To poll without posting progress you can call CheckRequest().
/// If your code neither posts progress nor polls for pause/cancel requests
/// then these methods are not needed.  
/// <p>
/// These classmethods are lightweight, and operate in shared memory that is
/// automatically associated with the process that called <METHOD>Run</METHOD>.
/// They do not modify any globals or this object.  Calling them does not require
/// an oref and if called in a process that has not called <METHOD>Run</METHOD>,
/// these $system functions do nothing.  This design means they can be placed into
/// subroutines which are only sometimes called within the context of your
/// background task subclass, and in low-level subroutines where it may be
/// impractical to pass an oref all the way down the stack.
/// <p>
/// <b>Detailed Guide</b>
/// <p>
/// The paradigm described above is designed for maximum flexibility with existing
/// code.  Simple status information like <PROPERTY>RunningState</PROPERTY>, 
/// <PROPERTY>FinalStatus</PROPERTY>, and others are reported to users without 
/// any changes; you simply create a subclass with an <METHOD>Execute</METHOD>
/// method that wraps an existing API.  Cancel and pause can optionally be offered
/// for basic single-processed routines via direct suspend/resjob.  If your code has
/// existing progress reporting facilities, they can be adapted into the
/// <METHOD>GetProgress</METHOD> callback.  Otherwise, if desired, you can enhance
/// existing code to periodically post progress updates via $system.BGUtil.PostProgress(),
/// and they will automatically be seen via this infrastructure (without any need
/// to implement GetProgress()).
/// <p>
/// The following steps can be used as a guide
/// <p>
/// 1. Define a subclass of this class, named after the utility/operation/API it implements.
/// <p>
/// 2. Optionally, override <PARAMETER>PAUSEDISPOSITION</PARAMETER> and 
/// <PARAMETER>CANCELDISPOSITION</PARAMETER> to allow pause and/or cancel requests.
/// <p>
/// 3. Provide an implementation of <METHOD>Execute</METHOD> (which may just call a
/// pre-existing API).  If desired, update that lower-level code to post progress with
/// $system.BGUtil.PostProgress().
/// (See <CLASS>%SYSTEM.BGUtil</CLASS> for further reference).
/// <p>
/// 4. Optionally, define any additional properties you wish to maintain and report to the
/// operator as part of the status display.  Define those properties in the subclass and
/// override <METHOD>GetDisplayInfo</METHOD> to include them in the display.  Your property
/// may be relatively static, or may reflect an additional detail about progress.
/// An example of a static property is a "Dataabase" property that set to the
/// database path passed as argument.  The value should be set in
/// <METHOD>OnStarting</METHOD> based on the arguments passed. </li>
/// For an example of a progress-related property imagine a "CurrentFile" property that
/// contains the file name in a task that processes multiple files.  
/// <p>
/// To ensure that progress-related properties behave properly create them as follows.
/// First, see <METHOD>GetProgress</METHOD> documentation, and include the necessary
/// information in <PROPERTY>ProgressDetails</PROPERTY> (in the CurrentFile example,
/// that means retrieving the filename and returning it as part of the 'detail' output argument).
/// Then, define property CurrentFile as "Calculated,SQLComputed", adding the compute code to
/// derive its value from <PROPERTY>ProgressDetails</PROPERTY>.  Finally, override 
/// <METHOD>GetDisplayInfo</METHOD> to include CurentFile in the progress display.
/// <p>
/// 5. Optionally, override <METHOD>OnStarting</METHOD> to do any argument validation you
/// desire.  Errors returned here are presented to the user immediately in <METHOD>Start</METHOD>.
Method Execute(args) As %Status [ Abstract, Internal, Private ]
{
}

/// Optional method to override in subclasses.  Called in the process that starts the
/// background task to validate arguments and set any static properties.  After this
/// method returns, the object will be saved and visible to operators for the first time
/// with <PROPERTY>RunningState</PROPERTY> set to "Starting".  Failure returned from
/// this method causes <METHOD>Start</METHOD> to fail.
Method OnStarting(args) As %Status [ Internal, Private ]
{
	quit $$$OK
}

/// Optional method to override in subclasses.  Called in the main process that will execute
/// the task code.  When this method returns, the object is saved with
/// <PROPERTY>RunningState</PROPERTY> set to "Running" and then <METHOD>Execute</METHOD>
/// will be called.  This method exists for subclasses to save any static properties
/// which require information from the main process.
/// At the time that this method runs, <METHOD>Start</METHOD> has already returned success.
/// You should only return errors from this method in exceptional cases.  Errors returned
/// will be recorded as the <PROPERTY>FinalStatus</PROPERTY> of this object.
Method OnRunning(args) As %Status [ Internal, Private ]
{
	quit $$$OK
}

/// Optional method to override in subclasses to compute progress or to refine progress
/// metrics posted to shared memory.  On entry, pass-by-reference parameters <i>current</i>,
/// <i>total</i> and <i>details</i> have the values last posted to memory (if any calls to
/// $system.BGUtil.PostProgress() were made).  Subclasses may modify their
/// values (perhaps based on their input values, or by retrieving progress information via
/// an external mechanism).  Subclasses may also assign a value to <i>units</i>.  The values
/// on output become values of the namesake properties <PROPERTY>ProgressTotal</PROPERTY>,
/// <PROPERTY>ProgressCurrent</PROPERTY>, <PROPERTY>ProgressUnits</PROPERTY>, and
/// <PROPERTY>ProgressDetails</PROPERTY>.  
/// <p>
/// Note that on input, <i>details</i> is an integer fetched from memory, but subclasses may
/// transform it into any string on output (<PROPERTY>ProgressDetails</PROPERTY> is a %String).
/// <PROPERTY>ProgressDetails</PROPERTY> is not displayed by default; it is a property from
/// which other calculated properties can derive their values.  By putting the code to retrieve
/// that progress information here, rather than directly in the compute code for such properties,
/// all progress-related information can be captured in the same place and at the same moment as
/// other progress information (perhaps atomically depending on your implementation).
/// <p>
/// This method is called only once each time the object is reloaded, rather than on each
/// reference to the property, so it presents this object as a "snapshot" of the progress at the
/// time it was loaded/queried.
/// <p>
/// This method is called from any process that opens or queries this object while
/// <PROPERTY>RunningState</PROPERTY> is "Running".  It is possible that the running
/// job has exited, either normally (due to a race between this method and the main process),
/// or abnormally, or due to cancellation.  This code must expect those possibilities.
/// If the caller finds that the job exited and the state was still Running, the state
/// will be changed to Exited, this method wil be called, the final progress information
/// will be stored, and it will not be called again.
/// <p>
/// This is also called once from the main job itself after <METHOD>Execute</METHOD>
/// returns in order to update and store final progress information, after which this
/// method will not be called again.
Method GetProgress(ByRef current As %Integer, ByRef total As %Integer, ByRef details As %String, ByRef units As %String) As %Status [ Internal, Private ]
{
	quit $$$OK
}

/// Optional method to override in subclasses to control how the task is to be
/// displayed to users.  
/// <p>
/// Returns $ListBuild(tasktype) where 'tasktype' is what the task modeled by
/// the subclass is called (e.g. Database Defragmentation).  This method may
/// additionally return an output array 'props' that describes how to display
/// properties defined in this subclass.  The form of the output array is
/// <br><br>
///  props(i)=$listbuild(propertyname,label,qualifiers)
/// <br><br>
/// where the following meanings apply
/// <li>i - A numeric index, starting at 1, and incrementing for each subclass property to display </li>
/// <li>propertyname - The name of the property to display </li>
/// <li>label - A (localized) string label to display for this property </li>
/// <li>qualifiers - A string of letter qualifiers that affect how the property will be displayed (see below) </li>
/// <p>
/// <b>qualifiers</b> supported 
/// <li>"p" - Progress property; place this property with the standard progress
/// information.  Such properties typically have values derived from
/// <PROPERTY>ProgressDetails</PROPERTY>, which is populated by the subclass in 
/// <METHOD>GetProgress</METHOD>.</li>
ClassMethod GetDisplayInfo(Output props) As %List [ Internal ]
{
	quit $ListBuild(..%ClassName(1))
}

/// Subroutine of <METHOD>Register</METHOD>
Method RegisterSub(args...) As %Status [ Final, Internal, Private ]
{
	#;Set read-only properties
	set i%StartTime=$zdt($h,3)
	set i%Namespace=$namespace
	do ..SetRunningState($$$BGTaskStarting)
	set ..JobNum=$zu(61)
	set ..JobID=$zu(61,30,$zu(61))
	set rc=$system.BGUtil.AllocateMemory()
	if rc="" {
		$$$SevereMsg("%SYS.BackgroundTask: no available memory slots to register")
		return $$$ERROR($$$BGTaskNoMem)
	}
	set ..MemIdx=$list(rc,1)
	set ..Version=$list(rc,2)
	$$$QUITONERROR(sc,..OnStarting(args...))
	$$$QUITONERROR(sc,..%Save())
	return $$$OK
}

/// On closing the object if we're the job that created it and the shared memory is 
/// still marked 'new' (meaning it was never run), free it and delete the object.
Method %OnClose() As %Status [ Final, Internal, Private, ServerOnly = 1 ]
{
	if $system.BGUtil.FreeMemory(..MemIdx,..Version,1) {
		if ..%Id() {
			set sc=..%DeleteId(..%Id())
			if $$$ISERR(sc)	{ $$$WarnMsg("%SYS.BackgroundTask: failed to delete on closing unused object, "_$system.Status.GetErrorText(sc)) }
		}
	}
	return $$$OK
}

/// If we're called to delete an object that still has shared memory, free it first.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Final, Internal, Private, ServerOnly = 1 ]
{
	set this=..%Open(oid,4,.sc)
	return:$$$ISERR(sc) sc
	if ($system.BGUtil.GetInfo(this.MemIdx,this.Version)'="")
	     && '$system.BGUtil.FreeMemory(this.MemIdx,this.Version) {
		return $$$ERROR($$$BGTaskMemoryInUse)
	}
	return $$$OK
}

/// SQLCompute code for <PROPERTY>ExternalState</PROPERTY>
Method GetExternalState(stored) As %Status [ Final, Internal ]
{
	set retval=stored
	try {
		set runstate=$listget(stored)
		quit:((runstate'=$$$BGTaskStarting) && (runstate'=$$$BGTaskRunning))
		#; In starting and running state, both the memory and the job must exist.
		#; If we find that it doesn't we first have to check to see if the state in the global
		#; has changed (there was just a race between this job loading from the global and the
		#; main job advancing to a new state).  If the global state is unchanged, then we
		#; will clean up memory and update the stored state.  If the global has changed, then we
		#; simply ignore it and use the older state from the time that all the other properties
		#; were loaded.
		set (exited,paused,locked)=0
		set meminfo=$system.BGUtil.GetInfo(..MemIdx,..Version)
		if (meminfo="") || '..JobIsRunning() {
			#;Job is gone.  Is it just because the state changed in the interim?
			#;Lock first since we want to make changes to the storage
			set sc=..%LockId(..%Id())
			set locked=$$$ISOK(sc)
			set curstored=..ExternalStateStoredGetStored(..%Id())
			if runstate=$listget(curstored) {
				#; Stored state is unchanged, so we know that this wasn't just a
				#; race with the task legitimately finishing.  Get latest info from
				#; memory, which includes the last progress update before it exited.
				set meminfo=$system.BGUtil.GetInfo(..MemIdx,..Version)
				set exited=1
			}
		} elseif runstate=$$$BGTaskRunning {
			#; See if it's really paused (we don't store paused state in the object).
			#; If pause is via suspend request, use $zu(61,4,j) to check the pstate.
			if ..#PAUSEDISPOSITION=1 {
				set paused=$listget(meminfo,$$$BGUtilGetInfoPaused)
			} elseif ..#PAUSEDISPOSITION=-1 {
				#; Check for pstate==SUSP and make sure it's really still our job
				set paused=(+$zu(61,4,..JobNum)=18)&&..JobIsRunning()
			}
		}
		if runstate=$$$BGTaskRunning {
			set request=$listget(meminfo,$$$BGUtilGetInfoRequest)
			set:request<0 request=-request
			set newstate=$select(exited&&(request=$$$BGTaskReqCancel):$$$BGTaskCancelled,
			                     exited:$$$BGTaskExited,
			                     paused:$$$BGTaskPaused,
			                     1:runstate)
			if (meminfo'="") {
				#; Set up ExternalState so that the callback can see the other properties.
				#; We'll update it again based on the progress values returned.
				set progresscur=$listget(meminfo,$$$BGUtilGetInfoProgressCurrent)
				set progresstot=$listget(meminfo,$$$BGUtilGetInfoProgressTotal)
				set progressdet=$listget(meminfo,$$$BGUtilGetInfoProgressDetail)
				set ..ExternalState=$listbuild(newstate,request)
				try {
					set sc=..GetProgress(.progresscur,.progresstot,.progressdet,.progressunits)
				} catch e {
					set sc=e.AsStatus()
				}
				#; Progress reporting can be messy and the total might have been just a guess
				#; so if the current count sloshed over the total, adjust the total up.
				if progresstot && (progresscur > progresstot) {	set progresstot=progresscur}
				if $$$ISERR(sc) { set (progresscur,progresstot,progressdet,progressunits)="" }
				set (retval,..ExternalState)=$listbuild(newstate,request,progresscur,progresstot,progressunits,progressdet,sc)
			} else {
				set retval=$listbuild(newstate)_$list(curstored,2,*)
			}
		} else {
			set:exited $list(retval,1)=$$$BGTaskExited
		}
		if exited && locked {
			#; We are cleaning up after a job that exited abnormally and we have exclusive
			#; access to the object
			set ..JobID=0
			set ..JobNum=0
			#; saves the last progress
			set ..ExternalStateStored=retval
			if (meminfo'="") && '$system.BGUtil.FreeMemory(..MemIdx,..Version) {
				#;Freeing memory should always work in this state.
				$$$WarnMsg("%SYS.BackgroundTask: failed to free memory on loading data for task that exited in Running state (idx="_..MemIdx_", version="_..Version_", info="_$listtostring(meminfo)_")")
			}
			set ..MemIdx=-1
			$$$THROWONERROR(sc,..%Save())
		}
	} catch {}
	do:$get(locked) ..%UnlockId(..%Id())
	return $get(retval)
}

/// Subroutine of <METHOD>Run</METHOD> to mark the task as completed.
Method End(status As %Status) As %Status [ Final, Internal, Private ]
{
	try {
		#; Pick up final progress to store in the object
		set meminfo=$system.BGUtil.GetInfo()
		if meminfo="" { $$$ThrowStatus($$$ERROR($$$BGTaskNotRunningInJob)) }
		set (..ExternalState,..ExternalStateStored)=..GetExternalState(..ExternalState)
		#; Lock the object before we free the memory so that anyone loading
		#; doesn't see the memory gone before the final progress is stored.
		$$$THROWONERROR(sc,..%LockId(..%Id()))
		set locked=1
		if '$system.BGUtil.ProcessEnd() || (..PID'=+$job)
		      || (..JobID'=$zu(61,30,$zu(61))) {
			#; ProcessEnd returns failure if called from the wrong process.
			#; Also make sure that we're working in the right object. We don't
			#; want to clear MemIdx in the wrong object, but we will call
			#; ProcessEnd first because something is screwed up and we might
			#; as well try to free whatever memory this job thinks it has.
			$$$ThrowStatus($$$ERROR($$$BGTaskNotRunningInJob))
		}
		set i%FinalStatus=status
		do ..SetRunningState($select($$$ISOK(status):$$$BGTaskDone,1:$$$BGTaskError))
		set i%MemIdx=-1
		set i%JobID=0
		set i%JobNum=0
		$$$THROWONERROR(sc,..%Save())
	} catch err {}
	do:$get(locked) ..%UnlockId(..%Id())
	if $get(err) {
		$$$WarnMsg("%SYS.BackgroundTask: failed while recording final state - "_err.DisplayString())
		return err.AsStatus()
	}
	return $$$OK
}

/// Called with the JOB command from <METHOD>Start</METHOD>
ClassMethod Child(id As %Integer) [ Final, Internal ]
{
	set this=..%OpenId(id,,.sc)
	#; If the job took too long to start, the parent may have given up,
	#; deleted the object and reported failure to the user.  So assume
	#; that failure to load the object need not be reported.
	do:this this.Run(%BackgroundTaskArgs...)
}

/// Private method for setting RunningState because it's readonly externally and has a shadow copy stored
Method SetRunningState(state) [ Final, Internal, Private ]
{
	set $list(i%ExternalState,1)=state
	set $list(i%ExternalStateStored,1)=state
}

/// Implementation of admin requests to cancel, pause, resume
Method Request(request) As %Status [ Final, Internal, Private ]
{
	if '$system.Security.Check($$$AdminOperateResourceName,$$$PermUseName) {
		return ($$$ERROR($$$OperationRequires2,$$$PermUseName,resourcename,$$$AdminOperateResourceName))
	}
	try {
		#; We need an interlock here for several reasons
		#;  - We want to get any current request value and know that it can't 
		#;    change if someone else is concurrently running this method.
		#;  - We want to interlock with someone loading the object so that if
		#;    they see the job exited or paused, they also see the request code
		#;    that caused it so that they can display correct state.
		$$$THROWONERROR(sc,..%LockId(..%Id()))
		set locked=1
		$$$THROWONERROR(sc,..%Reload())
		set direct=0
		if request=$$$BGTaskReqCancel {
			if '..#CANCELDISPOSITION { $$$ThrowStatus($$$ERROR($$$BGTaskRequestNotAllowed)) }
			if '..CancelIsAvailable { $$$ThrowStatus($$$ERROR($$$BGTaskRequestNotAllowedState)) }
			set:..#CANCELDISPOSITION=-1 direct=1
		} elseif request=$$$BGTaskReqPause {
			if '..#PAUSEDISPOSITION { $$$ThrowStatus($$$ERROR($$$BGTaskRequestNotAllowed)) }
			if '..PauseIsAvailable { $$$ThrowStatus($$$ERROR($$$BGTaskRequestNotAllowedState)) }
			set:..#PAUSEDISPOSITION=-1 direct=1
		} elseif request=$$$BGTaskReqResume {
			#; The disposition towards resume requests is identical to pause
			#; but the state requirements are separate. 
			if '..#PAUSEDISPOSITION { $$$ThrowStatus($$$ERROR($$$BGTaskRequestNotAllowed)) }
			if '..ResumeIsAvailable { $$$ThrowStatus($$$ERROR($$$BGTaskRequestNotAllowedState)) }
			set:..#PAUSEDISPOSITION=-1 direct=1
		}
		if 'direct {
			#; set to poll for this request type
			if '$system.BGUtil.SetRequest(..MemIdx,..Version,request) {
				$$$ThrowStatus($$$ERROR($$$BGTaskNotRunning))
			}
		} else {
			#; We're sending a direct resjob or suspend request.
			#; Make sure the pid is still running and matches the job number & id.
			#; This isn't foolproof since the pid could exit and get reused right
			#; after this check.
			if '..JobIsRunning() {
				$$$ThrowStatus($$$ERROR($$$BGTaskNotRunning))
			}
			if '$case(request,$$$BGTaskReqCancel:  $zu(4,..PID)
			                 ,$$$BGTaskReqPause:   $zu(143,..PID,1)
			                 ,$$$BGTaskReqResume:  $zu(143,..PID,0)) {
				$$$ThrowStatus($$$ERROR($$$BGTaskJobSignalFailed))
			}
			#; Store negative value as a signal that the request was sent.
			#; Negative values are ignored by CheckRequest and PostProgress.
			do $system.BGUtil.SetRequest(..MemIdx,..Version,-request)
		}
	} catch err {}
	if $get(locked) { do ..%UnlockId(..%Id()) }
	return:$get(err) err.AsStatus()
	return $$$OK
}

/// Helper function used to check that the job recorded as running this task is running.
/// It checks that PID still has the same job number and job id, meaning that the PID hasn't
/// been reused.
Method JobIsRunning() As %Boolean [ Internal, Private ]
{
	if '..JobNum ||
	   ($zu(61,30,..JobNum)'=..JobID) ||
	   (..PID && (..PID'=$zu(61,..JobNum))) {
		return 0
	}
	return 1
}

/// Outputs and refreshes a monitoring screen displaying the current status.
/// Output goes to the principal device, which is assumed to be a terminal.
Method CHUIMonitor() [ Final, Internal ]
{
	try {
		set static=1
		set type=$list(..GetDisplayInfo(.array),1)
		$$$THROWONERROR(sc,..%Reload())
		set scrn=##class(%Library.CHUIScreen).%New()
		do scrn.AddLine("------------------------------------------------------------------------------")
		do scrn.AddLine(type_", ID="_..%Id()_", as of ","time")
		do scrn.AddLine("------------------------------------------------------------------------------")
		do scrn.AddLine("Start Time:     "_..StartTimeLogicalToDisplay(..StartTime))
		do scrn.AddLine("Namespace:      "_..Namespace)
		do scrn.AddLine("State:          ","state")
		for i=1:1 {
			quit:'$data(array(i))
			set qualifiers=$listget(array(i),3)
			continue:qualifiers["p"
			set text=$list(array(i),2)_": "
			set:$length(text)<16 text=text_$justify("",16-$length(text))
			do scrn.AddLine(text,"prop"_i,1)
		}
		do scrn.AddLine("Progress:       ","progress",1)
		do scrn.AddLine("                ","bar",1)
		for i=1:1 {
			quit:'$data(array(i))
			set qualifiers=$listget(array(i),3)
			continue:qualifiers'["p"
			set text=$list(array(i),2)_": "
			set:$length(text)<16 text=text_$justify("",16-$length(text))
			do scrn.AddLine(text,"prop"_i,1)
		}
		do scrn.AddLine("Final Status:   ","finalstatus",1)
		do scrn.AddLine("------------------------------------------------------------------------------")
		if '..HasEnded { 
			do scrn.AddLine("","info")
			do scrn.AddLine("","prompt")
			do scrn.AddLine("","confirm")
			set static=0
		}
		do scrn.Draw()
		do:'static scrn.UpdateField("info","Display will refresh automatically")
		for {
			set state=..RunningState
			set statestr=state
			set:..PID statestr=statestr_"  (PID: "_..PID_")"
			#; Display the final %Status when available
			set finalstatus=$select(..FinalStatus="":"",$$$ISOK(..FinalStatus):"OK",1:$system.Status.GetErrorText(..FinalStatus))
			#; Progress display follows documented rules for interpreting progress.
			if ..ProgressTotal {
				set percentage=$justify(100*..ProgressCurrent/..ProgressTotal,0,2)
#define BARLEN 60
				set $extract(bar,$$$BARLEN+2)="|",$extract(bar,1)="|"
				set nchars=percentage*$$$BARLEN\100
				for i=1:1:$$$BARLEN {
					if i>nchars {
						set $extract(bar,i+1)=" "
					} else {
						set $extract(bar,i+1)="#"
					}
				}
#undef BARLEN
				if ..ProgressUnits="" {
					set progress=percentage_"%"
				} else {
					set progress=..ProgressCurrent_" / "_..ProgressTotal_" "_..ProgressUnits_" ("_percentage_"%)"
				}
			} elseif ..ProgressCurrent && (..ProgressUnits'="") {
				set progress=..ProgressCurrent_" "_..ProgressUnits 
				set bar=""
			} else { set (progress,bar)="" }
			#; Now go update all the fields with the latest values
			do scrn.UpdateField("time",$zdt($h,3))
			do scrn.UpdateField("state",statestr)
			do scrn.UpdateField("finalstatus",finalstatus)
			do scrn.UpdateField("progress",progress)
			do scrn.UpdateField("bar",bar)
			for i=1:1 {
				quit:'$data(array(i))
				set prop=$list(array(i),1)
				do scrn.UpdateField("prop"_i,$method($this,prop_"LogicalToDisplay",$property($this,prop)))
			}
			#; If the task has ended we want to break the loop and not prompt.
			#; If this wasn't static (meaning we iterated at least once already),
			#; then notify the user that we're done monitoring. 
			if ..HasEnded {
				if 'static {
					do scrn.UpdateField("info",type_" ended (see status above)")
					do scrn.UpdateField("prompt","")
					write /bel
				}
				kill scrn
				write "Press any key to return."
				read *char
				quit
			}
			#; The task has not ended, so figure out what options are 
			#; available and prompt the user
			set promptstr="Press 'Q' to return"
			if ..PauseIsAvailable set promptstr=promptstr_", 'P' to pause"
			if ..ResumeIsAvailable set promptstr=promptstr_", 'R' to resume"
			if ..CancelIsAvailable set promptstr=promptstr_", 'C' to cancel"
			set promptstr=promptstr_": "
			do scrn.UpdateField("prompt",promptstr)
			read *char:1
			set char=$zcvt($c(char),"U")
			quit:(char="Q")||(char="^")
			set action=$case(char,"P":"Pause","R":"Resume","C":"Cancel",:"")
			if action'="" {
				set confirmstr=action_" "_type_"? (Enter 'Y' or 'N') "
				do scrn.UpdateField("confirm",confirmstr)
				read *yn
				if (yn=$ascii("Y")) || (yn=$ascii("y")) {
					set sc=$method($this,action)
					if $$$ISOK(sc) {
						do scrn.UpdateField("confirm",action_" requested.")
					} else {
						do scrn.UpdateField("confirm","Error requesting "_action)
					}
					hang 2
				}
				do scrn.UpdateField("confirm","")
			}
			$$$THROWONERROR(sc,..%Reload())
		}
	} catch err {
		kill scrn
		if $g(err) && (err.Name'="<INTERRUPT>") {
			write !,"Error in Monitor: ",err.DisplayString()
			write !
		}
	}
}

Parameter DOMAIN = "%Utility";

/// Disposition for cancel requests.
/// <p>
///  0 - not allowed<br>
///  1 - polls for cancel requests<br>
/// -1 - directly terminate the process 
Parameter CANCELDISPOSITION = 0;

/// Disposition for pause requests.
/// <p>
///  0 - not allowed<br>
///  1 - polls for pause requests<br>
/// -1 - directly pause the process 
Parameter PAUSEDISPOSITION = 0;

/// All database-oriented tasks running in a particular database
Query RunningInDatabase(dir As %String) As %SQLQuery [ Final, Internal ]
{
	SELECT ID,StartTime,DisplayType
	FROM SYS_Database.BackgroundFileCompact 
	WHERE Database=:dir and HasEnded = 0
			UNION 
	SELECT ID,StartTime,DisplayType
	FROM SYS_Database.BackgroundDefragment
	WHERE Database=:dir and HasEnded = 0
}

/// All database-oriented tasks.  This currently includes SYS.Database.BackgroundFileCompact and SYS.Database.BackgroundFileCompact
Query DatabaseList() As %SQLQuery [ Final ]
{
	SELECT ID,StartTime,DisplayType,Database,RunningState,HasEnded,ProgressTotal,ProgressCurrent
	FROM SYS_Database.BackgroundFileCompact
			UNION 
	SELECT ID,StartTime,DisplayType,Database,RunningState,HasEnded,ProgressTotal,ProgressCurrent
	FROM SYS_Database.BackgroundDefragment
	ORDER BY ID
}

/// Query background tasks of all types
Query ListAll() As %SQLQuery(CONTAINID = 1) [ Final ]
{
SELECT %ID,StartTime,Class,DisplayType,Namespace,RunningState,HasEnded,FinalStatus,
       ProgressCurrent,ProgressTotal,ProgressUnits
FROM %SYS.BackgroundTask
}

Storage Default
{
<Data name="BackgroundTaskDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>StartTime</Value>
</Value>
<Value name="3">
<Value>Namespace</Value>
</Value>
<Value name="4">
<Value>FinalStatus</Value>
</Value>
<Value name="5">
<Value>PID</Value>
</Value>
<Value name="6">
<Value>MemIdx</Value>
</Value>
<Value name="7">
<Value>Version</Value>
</Value>
<Value name="8">
<Value>JobNum</Value>
</Value>
<Value name="9">
<Value>JobID</Value>
</Value>
<Value name="10">
<Value>ExternalStateStored</Value>
</Value>
</Data>
<DataLocation>^%SYS.BackgroundTaskD</DataLocation>
<DefaultData>BackgroundTaskDefaultData</DefaultData>
<IdLocation>^%SYS.BackgroundTaskD</IdLocation>
<IndexLocation>^%SYS.BackgroundTaskI</IndexLocation>
<StreamLocation>^%SYS.BackgroundTaskS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
