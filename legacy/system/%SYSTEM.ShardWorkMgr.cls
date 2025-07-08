/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Manage distributing work to other systems in a sharded environment.
/// This is modelled on the <class>%SYSTEM.WorkMgr</class> as closely as possible. To use this you first
/// create an instance of this class, this acts as the container for the units of work you then request.
/// Finally you wait for this work to complete or return errors.
Class %SYSTEM.ShardWorkMgr Extends AbstractWorkMgr
{

/// Broadcast a task to be run via the Work Queue Manager on all systems that form part of <var>set</var> of machines.
/// Once the work is broadcast you can <method>Sync</method> to wait for all work to complete or <method>WaitOne</method>
/// to get notifications of individual completions.<p>
/// The <var>set</var> supports the following values for a sharding system:<ol>
/// <li>DS or data : All shard data nodes</li>
/// <li>QD or compute : A set of shard compute/query nodes</li>
/// <li>all : All shard nodes (the default)</li>
/// <li>instance : All instances that are part of the shard set</li></ol>
/// Note that QD/compute will pick a set of compute/query nodes that cover the entire extent and run the broadcast on these
/// nodes so it will be able to see all the data. If a shard setup has two namespace on a single instance that are part
/// of the shard cluster then 'instance' will only run the logic in one of the namespace on this instance so it is useful
/// for collecting system wide information.<p>
/// Returns a %Status code if the work was queued correctly, note that to see if the work completed you need to call
/// <method>Sync</method> method and check the returned %Status value for this.
/// Pass the entry point to call in <var>work</var> argument. This can be either '##class(Classname).ClassMethod'
/// or '$$entry^rtn' and it is expected to return a %Status code. If you want to call a function
/// that does not return any value on completion then prepend the class syntax with '=' such as '=##class(Classname).ClassMethod'
/// or for calling a function do not include the '$$' for example 'entry^rtn'.
/// The item being called may also throw exceptions in order to indicate an error happened which is trapped and converted
/// to a %Status value to be returned in the parent process. You can also pass additional
/// arguments including arrays by reference. Note that the size of the data passed in these arguments should be kept
/// relatively small, if there is a large amount of information that needs to be passed then put this in a global.
/// The security context of the caller is recorded when this function is called and is used when the work is executed.
/// Output the work unit makes to the current device will be trapped and relayed to the parent process after this work unit
/// has complted and when the parent process is waiting for work to be completed. If a work unit wishes to flush output before
/// the work unit has completed then then call 'Do $system.WorkMgr.Flush()'
/// Work units may write to the public variable <var>%result</var> which will be relayed to the parent process in the
/// <method>WaitOne</method> call via the byref <var>workresult</var> argument.
Method Broadcast(set As %String, work As %String, args... As %String) As %Status
{
	Merge group=i%group
	Set sc=$$Broadcast^%SYS.WorkQueueMgr(.group,.set,.work,.args)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Map the work over a set of id's in a class.<p>
/// Takes the <var>classname</var> which the id's belong to,
/// a task to be run via the Work Queue Manager on all  systems that form part of <var>set</var> of machines.
/// The <var>set</var> supports the following values for a sharding system:<ol>
/// <li>DS or data : All shard data nodes</li>
/// <li>QD or compute : A set of shard compute/query nodes</li></ol>
/// Note that QD/compute will pick a set of compute/query nodes that cover the entire extent and run the work on these
/// nodes so it will be able to see all the data.<p>
/// The <var>idlist</var> is a $lb of IDs to process, or a local array subscripted by the ID to process passed in by reference.
/// If idlist="" then we will map the work over all the IDs in the extent.
/// Returns a %Status code if the work was queued correctly, note that to see if the work completed you need to call
/// <method>Sync</method> method and check the returned %Status value for this.
/// Pass the entry point to call in <var>work</var> argument. If this is an instance method indicated by a leading '..' for example
/// '..Method' we will call this method on the instance of the shard local class associated with <var>classname</var> class for this specific id.
/// Also supported is either '##class(Classname).ClassMethod' or '$$entry^rtn' where the first argument being passed in to this
/// class method or function will be the 'id' of the element to process, the second argument will be 'classname' followed by
/// and additional argumented passed in this method.
/// In all these cases the method/function is expected to return a %Status code. If you want to call a function
/// that does not return any value on completion then prepend the class syntax with '=' such as '=##class(Classname).ClassMethod'
/// or for calling a function do not include the '$$' for example 'entry^rtn'.
/// The item being called may also throw exceptions in order to indicate an error happened which is trapped and converted
/// to a %Status value to be returned in the parent process. You can also pass additional
/// arguments including arrays by reference. Note that the size of the data passed in these arguments should be kept
/// relatively small, if there is a large amount of information that needs to be passed then put this in a global.
/// The security context of the caller is recorded when this function is called and is used when the work is executed.
/// Output the work unit makes to the current device will be trapped and relayed to the parent process after this work unit
/// has completed and when the parent process is waiting for work to be completed. If a work unit wishes to flush output before
/// the work unit has completed then then call 'Do $system.WorkMgr.Flush()'
/// Work units may write to the public variable <var>%result</var> which will be relayed to the parent process in the
/// <method>WaitOne</method> call via the byref <var>workresult</var> argument.
Method Map(set As %String, classname As %String, ByRef idlist As %List, work As %String, args... As %String) As %Status
{
	Merge group=i%group
	Set sc=$$Map^%SYS.WorkQueueMgr(.group,.set,.classname,.idlist,.work,.args)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Internal method for use with sharding only.<br>
/// <var>localSystem</var> is the reference of this local systems IRISLOCALDATA database from the remote system we will queue work on.
/// Add a task to the Work Queue Manager runqueue on a remote machine. You get a %Status if the work was queued correctly.
/// <var>remoteSystem</var> the namespace or implied reference that maps to the remote systems
/// IRISLOCALDATA database so you can form a valid global reference with '^|remoteSystem|IRIS.WorkQueue' that will write data to the target system.
/// <var>namespace</var> is the remote namespace we wish this work to be done in.
/// The remote work is run in the namespace with the same name as the current namespace when you create the work group.
/// You pass the entry point to call in 'work' argument. This can be either '##class(Classname).ClassMethod'
/// or '$$entry^rtn' and it is expected to return a %Status code on completion. If you want to call a function
/// that does not return any value on completion then prepend the class syntax with '=' such as '=##class(Classname).ClassMethod'
/// or for calling a function do not include the '$$' for example 'entry^rtn'.
/// The item being called may also throw exceptions in order to indicate an error happened which is trapped and converted
/// to a %Status value to be returned in the parent process. You can also pass additional
/// arguments including arrays by reference. Note that the size of the data passed in these arguments should be kept
/// relatively small, if there is a large amount of information that needs to be passed then put this in a global.
/// The security context of the caller is also recorded when this function is called so it can be used when the work
/// is executed.
Method QueueShard(localSystem As %String, remoteSystem As %String, namespace As %String, work As %String, args... As %String) As %Status [ Internal ]
{
	Merge group=i%group
	Set sc=$$queueShardWork^%SYS.WorkQueueMgr(2,.localSystem,.remoteSystem,.namespace,.group,.work,.args)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// Internal method for use with sharding only.<br>
/// Post a $system.Event to the remote system where <var>remoteSystem</var> the namespace or implied reference that maps to the remote systems
/// IRISLOCALDATA database so you can form a valid global reference with '^|remoteSystem|IRIS.WorkQueue' that will write data to the target system.
/// <var>event</var> is the global name to issue a $system.Event.Signal(event) on.
ClassMethod PostRemoteEvent(remoteSystem As %String, event As %String) [ Internal ]
{
	Do postRemoteEvent^%SYS.WorkQueueMgr(.remoteSystem,.event)
}

}
