/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implement some abstract interfaces for Work Queue Manager subclasses
Class %SYSTEM.AbstractWorkMgr Extends %SystemBase [ Abstract ]
{

/// Group assocaited with this work.
Property group As %Integer [ Internal, MultiDimensional ];

/// When the work queue oref is killed or goes out of scope this is the timeout we pass to the call the destructor
/// makes to delete the work queue. The delete queue logic will wait for this timeout period for the worker/s to respond
/// but if the worker/s is/are still busy it will force these processes down. 
Property DeleteTimeout As %Integer [ InitialExpression = 1 ];

/// Internal property not to be set by user code.
/// <p>If true skip normal cancel work we will do for shard queue.
Property completed As %Boolean [ InitialExpression = 0, Internal ];

/// Disable output from worker jobs
Property suppressoutput As %Boolean [ Internal, Private ];

/// For local WQM group after the work group is created the number of workers allocated to this group.
/// Note this is the number of jobs we requested, not the number actively working for
/// this group at this moment. The active number is <property>NumActiveWorkers</property>.
Property NumWorkers As %Integer;

/// For local WQM groups number of active workers attached to this group. If the system is at the limit
/// then we limit the number of worker jobs so you may need to wait for existing worker
/// jobs to become free in order to attach to your work group. If queue is
/// detached will return -1.
Property NumActiveWorkers As %Integer [ Calculated ];

Method NumActiveWorkersGet() As %Integer
{
	RETURN $$NumActiveWorkerJobs^%SYS.WorkQueueMgr(i%group)
}

/// Initialize the worker jobs so they are ready to start accepting work items. In the qspec that is passed
/// you can determine if you want output with the 'd' flag. If you wish to disable multiple jobs and process
/// the work in this parent process pass in <var>numberjobs</var>=0. This returns an instance of the worker queue manager
/// which you can then queue work against. If you wish to specify how many workers you require then pass
/// the <var>numberjobs</var> equal to the number you require.<p>
/// <var>category</var> allows you to specify the pool of workers this group should be taken from.
/// Note that we <var>qstruct</var> to specify /multicompile is deprecated. The /multicompile qualifier is not used by the work queue manager
/// and passing this qualifier into this class has no effect.
Method %OnNew(ByRef qstruct As %String, numberjobs As %Integer, category, target) As %Status [ Private, ServerOnly = 1 ]
{
	$$$qualifierParseDirect(sc,qstruct) If $$$ISERR(sc) Quit sc
	Set group=-1
	Set sqm=($classname()="%SYSTEM.ShardWorkMgr")
	If sqm Set i%NumWorkers=$get(numberjobs)
	Set sc=$$CreateWorkers^%SYS.WorkQueueMgr(.group,,.numberjobs,$select(sqm:3,1:0),,.category) If $$$ISERR(sc) RETURN sc
	Merge i%group=group
	Set:'sqm i%NumWorkers=numberjobs
	Set i%suppressoutput='$$$qualifierGetValue(qstruct,"displaylog")
	set:sqm $SYSTEM.Context.SN().groupId = group
	RETURN $$$OK
}

Method %OnClose() As %Status [ Internal, Private ]
{
	Merge group=i%group
	Set sc=$$DeleteGroup^%SYS.WorkQueueMgr(.group,$get(i%DeleteTimeout,1),,$get(i%completed))
	Kill i%group
	RETURN sc
}

/// Deprecated method implemented for compatibility with code used to calling 'Initialize' method but new users should call %New
/// to create an instance of this class.
ClassMethod Initialize(qspec As %String = "", ByRef sc As %Status, numworkers As %Integer) As AbstractWorkMgr [ Deprecated ]
{
	Set oref=..%New(.qspec,.numworkers)
	If oref=$$$NULLOREF { Set sc=$get(%objlasterror) } Else { Set sc=$$$OK }
	Quit oref
}

/// Internal method not for use
ClassMethod InitializeClass(iscname As %String, qspec As %String = "", ByRef sc As %Status, numworkers As %Integer) As AbstractWorkMgr [ Internal ]
{
	Set oref=..%New(.qspec,.numworkers)
	If oref=$$$NULLOREF {
		Set sc=$get(%objlasterror)
	} Else {
		Set sc=oref.Setup("$$CompileSetup^%occCompile",iscname) If $$$ISERR(sc) RETURN $$$NULLOREF
		Set sc=oref.TearDown("$$CompileEnd^%occCompile") If $$$ISERR(sc) RETURN $$$NULLOREF
	}
	Quit oref
}

/// If you queue a large number of units of work and there is some common setup needed by any process that will
/// run one of these units of work rather than having this setup work done for every work unit you can initalize the
/// worker process once with this method, then it can process any number of work units in this group and when it is done
/// it will run the <method>TearDown</method>. So if you call this method for a work group we will ensure this Setup
/// entry point is called before the worker runs the first unit in this work group. This must be called before you queue
/// any work and the arguments are the same as for the <method>Queue</method>.
Method Setup(work As %String, args... As %String) As %Status
{
	RETURN $$realQueue^%SYS.WorkQueueMgr(i%group,0,.work,,.args)
}

/// This is a companion method to <method>Setup</method> to restore a workers process to the previous state if
/// setup work was done.
/// The arguments are the same as for <method>Queue</method>. This must be called before you queue work.
Method TearDown(work As %String, args... As %String) As %Status
{
	RETURN $$realQueue^%SYS.WorkQueueMgr(i%group,1,.work,,.args)
}

/// Normally when a work group is deleted the delete/close is synchronous and so waits for all the worker jobs to finish
/// or be terminated before it returns to the caller. This means the caller can be sure all work has finished and it can
/// cleanup any temporary storage or resources the workers may have been using. This method allows you to specify a callback
/// to be run when the work group is fully deleted which makes the delete/close of the work group asynchronous. So when the
/// work group is deleted it can return immediately to the caller, but the caller can not assume all work has been terminated.
/// Some of the workers may still be finishing their work or may be in the process of being terminated, however once the
/// workers are stopped we will fully delete the work queue and run this 'Cleanup' callback. Note that this callback is not run
/// in a worker that we have called <method>Setup</method> in.
Method Cleanup(work As %String, args... As %String) As %Status
{
	RETURN $$realQueue^%SYS.WorkQueueMgr(i%group,2,.work,,.args)
}

/// Clear any existing work from this work queue, it does this by removing the queue and creating a new one.
/// This will wait for up to <var>timeout</var> seconds for the workers to finish their current task before killing
/// the jobs. When we return from this function all work on the group has terminated so you can cleanup any temporary
/// globals etc used by the workers.
Method Clear(timeout As %Integer = 1) As %Status
{
	Merge group=i%group
	Set sc=$$DeleteGroup^%SYS.WorkQueueMgr(.group,timeout,1,i%completed)
	Kill i%group
	If $$$ISERR(sc) RETURN sc
	Kill group Set group=-1
	Set sc=$$CreateWorkers^%SYS.WorkQueueMgr(.group,,i%NumWorkers)
	If $$$ISERR(sc) RETURN sc
	Merge i%group=group
	RETURN $$$OK
}

/// After work has been queued this will wait for all the workers to complete. It will display any output the work
/// writes to the current device and it will also combine all the %Status codes/exceptions that the units of work report and
/// return this combined %Status. If the work queue is created with no workers then this will execute all the work in the current job
/// during this phase. When this returns all the work queued up to this point has been completed (see <method>Cleanup</method> for an exception).
/// This is the phase that will run the <method>QueueCallback</method> callbacks as the workers jobs report that work
/// units are complete. In the function/method called in the <method>QueueCallback</method> callback
/// you can reference the public variable '%workqueue' which is the oref pointing to the instance of the work queue class
/// to allow additional work to be queued.
/// <p>For information on <var>qSpec</var>, see 
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=ObjectScript+qspec">System Flags and Qualifiers</a>.</p>
Method Sync(qspec As %String, errorlog As %String) As %Status
{
	If $data(qspec) {
		$$$qualifierParseDirect(sc,qstruct) If $$$ISERR(sc) Quit sc
		Set suppressoutput='$$$qualifierGetValue(qstruct,"displaylog")
	} Else {
		Set suppressoutput=i%suppressoutput
	}
	New %workqueue Set %workqueue=$this
	Merge group=i%group
	Set sc=$$WaitForComplete^%SYS.WorkQueueMgr(.errorlog,.group,,,'suppressoutput)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// <p>For information on <var>qSpec</var>, see 
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=ObjectScript+qspec">System Flags and Qualifiers</a>.</p>
Method WaitForComplete(qspec As %String, errorlog As %String) As %Status [ CodeMode = call ]
{
..Sync(qspec,errorlog)
}

/// After work has been queued you can call this to process some work completion events and then return to the caller where the caller
/// will check the <var>atend</var> to see if all the work was processed and if not then you can call this method again
/// to process additional items until <var>atend</var> is true. <var>atend</var> will be true for the first time
/// when we have just received the last completion event for work that was queued.<br>
/// The conditions which control when it will return to the caller are controlled by <var>timeout</var> argument which has a default of -1:
/// <ul>
/// <li>Positive number : Return to the caller after one work complete event is received or after the specified number of seconds has elapsed.</li>
/// <li>0 : Keep looking for work completion events until no completions are waiting, then return to the caller. Useful for polling to
/// check if all work has been completed but then going to do some other work in this process.</li>
/// <li>-1 : Requires a callback queued in <method>QueueCallback</method>. In the callback set the public variable %exit to 1 to make this
/// 'Wait' call return to the caller. If the %exit is not set we will continue to wait for additoinal completion events until all have been
/// received or until a callback sets %exit=1. This is the default</li>
/// </ul> 
/// In the function/method called in the <method>QueueCallback</method> callback
/// you can reference the public variable '%workqueue' which is the oref of the instance of the work queue class
/// in order to queue additional work.
/// <p>For information on <var>qSpec</var>, see 
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=ObjectScript+qspec">System Flags and Qualifiers</a>.</p>
Method Wait(qspec As %String, ByRef atend As %Boolean, timeout As %Integer = -1) As %Status
{
	If $data(qspec) {
		$$$qualifierParseDirect(sc,qstruct) If $$$ISERR(sc) Quit sc
		Set suppressoutput='$$$qualifierGetValue(qstruct,"displaylog")
	} Else {
		Set suppressoutput=i%suppressoutput
	}
	New %workqueue Set %workqueue=$this
	If timeout=0 Set timeout=-5
	Merge group=i%group
	Set sc=$$WaitForComplete^%SYS.WorkQueueMgr(,.group,timeout,.atend,'suppressoutput)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// <p>Wait for one work unit to complete or we hit the timeout.
/// This is useful when you want to respond to individual completeion events in the parent process or you want to handle work unit errors
/// differently than WQM framework errors. If you only need to wait until all the work is completed then use the <method>Sync</method>.
/// Any errors in the WQM framework will be thrown as an exception which the caller should 'catch', in normal operation this will not occur.
/// The return value of the individual work unit or any errors thrown by running
/// the work unit are returned in the byref <var>worksc</var> %Status variable. If a timeout happens then we indicate this in the <var>worksc</var>
/// %Status variable as a error of $$$ERROR($$$MultiTimeout,timeout) error. You can check for this error code with 'If $$$ERRORISTYPE(sc,$$$MultiTimeout)'.</p>
/// <p>If a work unit was run then the array <var>workargs</var> is the argument list passed to the work unit, the first argument will be in <var>workargs(1)</var> and the second
/// argument will be in <var>workargs(2)</var> etc, so in the format when your function uses an 'workarg...' parameter. This provides context so you can understand any error
/// or other information the work unit has set.</p>
/// <p>When a work unit that is run sets result information into the public variable <var>%result</var> array this will be returned to the caller of WaitOne in the <var>workresult</var> byref array.
/// The method returns '1' to indicate it has either got a completion event or a timeout has occurred and '0' to indicate all completions have already been processed.
/// Any callback queued in <method>QueueCallback</method> are run in this method in the same way they are for <method>Sync</method> calls although when
/// using WaitOne there is no need for the callback mechanism.</p>
/// <p>Example use of this method is the following code. Any errors in WQM framework will be throw but return values from work units are returned in the <var>workargs</var> byref
/// value so they may be handled by the caller if wished.
/// <example>
/// Set queue=$system.WorkMgr.%New() If queue="" ; Report Error, can check %objlasterror for %Status code
/// For i=1:1:100 {
/// 	Set sc=queue.Queue("##class(MyClass).ClassMethod",i) If $$$ISERR(sc) ; Report Error
/// }
/// While queue.WaitOne(10,.sc,.args,.result) {
/// 	If $$$ISERR(sc) {
/// 		If $$$ERRORISTYPE(sc,$$$MultiTimeout) {
/// 			; Handle a timeout
/// 		} Else {
/// 			; Work unit returned %Status code or threw an expcetion, hanlde this here
/// 		}
/// 	} Else {
/// 		Write "Completed work unit ",args(1),!   ; As we have access to the argument list provided on the 'Queue'
/// 		Zwrite result  ; Any %result data from the work unit
/// 	}
/// }
/// </example>
Method WaitOne(timeout As %Integer = 9999, ByRef worksc As %Status, ByRef workargs As %Binary, ByRef workresult As %Binary) As %Boolean
{
	If $get(i%group(4))=1 RETURN 0
	New %workqueue Set %workqueue=$this
	Merge group=i%group
	Set sc=$$WaitForComplete^%SYS.WorkQueueMgr(,.group,"-6:"_timeout,.atend,,.workargs,.worksc,.workresult)
	Kill i%group Merge i%group=group
	If atend Set i%group(4)=1
	$$$ThrowOnError(sc)
	RETURN 1
}

/// Write out a list of the methods of this object to the console.
/// Pass the method name as an argument to see the full description for
/// this item.
ClassMethod Help(method As %String = "") As %String
{
	If method="" {
		Set class=##class(%Dictionary.CompiledClass).%OpenId($classname())
		If class=$$$NULLOREF Write "Internal error",! Quit
		
		Write "'Do "_$replace($classname(),"%SYSTEM.","$system.")_".Help(method)' "_$$$GetSimpleMessage("%Compiler","OBJHelp"),!!
		Write $$$GetSimpleMessage("%Compiler","OBJMethodList")_$classname(),!
		For index=1:1:class.Methods.Count() {
			Set method=class.Methods.GetAt(index)
			If $extract(method.Name)="%" Continue
			Set description=method.Description
			If description'="",method.Private'=1,'method.Internal {
				Set spec=method.FormalSpec
				Set s=""
				For a=1:1:$L(spec,",")  Set s=s_$S(s="":"",1:",")_$P($P(spec,",",a),":")
				Write !,method.Name,"(",s,")",!
				Write ?5,$zconvert($piece(description,$char(13)),"I","HTML"),!
			}
		}
	} Else {
		Write $$$GetSimpleMessage("%Compiler","OBJMethodDesc")_method_":"_$classname(),!
		Set obj=##class(%Dictionary.CompiledMethod).%OpenId($classname()_"||"_method)
		If obj=$$$NULLOREF||(obj.Internal) {
			Write !,"'"_method_"'"_$$$GetSimpleMessage("%Compiler","OBJMethodNotExist"),!
		} Else {
			Write !,method,"(",obj.FormalSpec,")",!
			Write $zconvert(obj.Description,"I","HTML"),!
		}
	}
}

}
