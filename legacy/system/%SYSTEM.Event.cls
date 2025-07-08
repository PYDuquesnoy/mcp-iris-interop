/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// The %SYSTEM.Event class provides an interface to the Event API.  <br> <br>
/// <!doctype html public "-//w3c//dtd html 4.0 transitional//en">
/// <html>
/// <head>
///    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
///    <meta name="GENERATOR" content="Mozilla/4.77 [en] (Windows NT 5.0; U) [Netscape]">
///    <title>Events Final</title>
/// </head>
/// <body>
/// 
/// <center><b><font size=+2>Event Queueing in InterSystems IRIS</font></b></center>
/// <b><font size=+1>Overview</font></b>
/// <p>This feature allows processes to go to sleep waiting for a wakeup event
/// for some resource. That "resource" can either be a "Named Resource" which
/// can be used to queue multiple processes - one of which will be awakened
/// for each wakeup event - or a Process ID Resource.
/// <p>There are 2 types of resources on which processes can be queued for
/// events:
/// <blockquote>
/// <ul>
/// <li>
/// Named resources (which may be either a name or a global reference and are
/// explicitly created and deleted), and</li>
/// 
/// <li>
/// Process ids (one of which implicitly exists for each process)</li>
/// </ul>
/// </blockquote>
/// A process can wait on any Named Resource or on its own Process Id, but
/// not on some other process' process id. A process can issue a wakeup to
/// any resource.
/// <p>There are fundamentally 4 operations on resources:
/// <blockquote>
/// <ul>
/// <li>
/// Create a resource (Named Resources only),</li>
/// 
/// <li>
/// Wait on a resource,</li>
/// 
/// <li>
/// Issue a Wakeup event for that resource, and</li>
/// 
/// <li>
/// Delete the resource (Named Resources only).</li>
/// </ul>
/// </blockquote>
/// For both types of resources, when a wakeup call is issued, it either: a)
/// wakes one of the processes that was waiting on that resource, or, if no-one
/// was waiting, it b) queues up a wakeup for that resource so that as soon
/// as a process tries to wait on that resource it immediately gets awakened.
/// Thus wakeups can be queued prior to someone actually going to sleep on
/// the resource.
/// <p>There is a one-to-one correspondence between wakeup events and process
/// wakeups. E.g. if 5 processes are waiting for a Named Resource and 3 wakeup
/// events occur for that resource, 3 of the processes will be issued wakeups.
/// Similarly, if only one process ever waits on a particular resource and
/// while the process is working on the result of one wakeup event 3 other
/// wakeup events are queued for it, the next 3 calls by that process to the
/// wait function for that resource will result in the process immediately
/// continuing.
/// <p>When multiple processes are waiting on a Named Resource there is no
/// guarantee as to which one will be awakened next. (Note only one process
/// can wait on a given Process ID since only the process with that PID can
/// wait on it.)
/// <p>If a wait is issued for a resource that doesn't exist, it is an error.
/// <p>If a wakeup is issued for a resource that doesn't exist or for a non-existent
/// PID, a 0 is returned to the caller.
/// <p>There is no networking support for these functions - processes
/// can only wait on and awaken resources on the same system.
/// <p><b><font size=+1>Named Resources</font></b>
/// <p>A "Named Resource" gets "created" by a system call and thereafter one
/// or more processes can wait on that resource for "wakeup" events for that
/// resource.
/// <p>Once a Named Resource is created, it continues in existence until either
/// it is explicitly deleted or the system is shutdown. Thus these resources
/// survive process termination.
/// <p>A "Named Resource" is a string representation of a valid identifier.
/// The syntax of the identifier is identical to the lock command.
/// <p><b><font size=+1>Process ID Resources</font></b>
/// <p>"Process ID Resources" are system-wide values corresponding to process identifiers (value of $J)
/// for cache processes. They are automatically
/// created when a process is created and automatically deleted when a process
/// exits. A process may wait only on its own process identifier.
/// <p><b></b>
/// <p>In the Methods below, ResourceName must be in $name format, or else a FUNCTION error is returned.
/// </body>
/// </html>
Class %SYSTEM.Event Extends Help [ Not ProcedureBlock, System = 4 ]
{

/// <p>Create a Named Resource.
/// <p>ResourceName is a Named Resource, e.g. 'Lab', '^Queue("main")', etc.
/// <p>Returns 0 if there was already a Named Resource by that name (in which
/// case this function is ignored), else creates it and returns 1.
/// <br>&nbsp;
ClassMethod Create(ResourceName As %String) As %Integer [ CodeMode = expression ]
{
$system.Event.Create(ResourceName)
}

/// <p>Wait on a resource.
/// <p>Resource, if present, is the name of a Named Resource or a null string.
/// The default value for Resource is the null string. A null string for Resource
/// means wait on my Process ID resource.
/// <p>The timeout is identical to the lock command timeout, and affects the
/// timeout in the same way (e.g., it can be integer or decimal values, it can be down to 100th seconds).
/// The default value of timeout is -1.
/// <p>An attempt to wait on a resource that doesn't exist is an error (ERUNDEF).
/// <p>Return value:
/// <ul>
/// <li>
/// -1 implies a delete of the resource occurred while we were waiting</li>
/// 
/// <li>
/// 0 implies a timeout occurred</li>
/// 
/// <li>
/// 1 implies we were awakened due to a wakeup event</li>
/// </ul>
ClassMethod Wait(ResourceName As %String = NULL, timeout As %Decimal = -1) As %Integer [ CodeMode = expression ]
{
$system.Event.Wait(ResourceName,timeout)
}

/// <p>Wait on a resource and receive a message.
/// <p>Identical to Event.Wait() except a string is returned along with the return code.  See Signal().
/// <p>Returns a $LIST item:
/// <ul>
/// <li>
/// Item #1 is the return code, identical to Wait().</li>
/// <li>
/// Item #2 is the string sent with the signal (a null string if no message was sent).</li>
/// </ul>
ClassMethod WaitMsg(ResourceName As %String = NULL, timeout As %Numeric = -1) As %List [ CodeMode = expression ]
{
$system.Event.WaitMsg(ResourceName,timeout)
}

/// <p>Wakeup a process waiting for a resource.
/// <p>Enqueues a wakeup event for a resource. Resource may be either a Named
/// Resource or a Process ID Resource. If it is a Process ID Resource, the
/// target process' PID is used (i.e. $J of the process to be awakened - which
/// must be an integer value.)
/// <p>A return value of 1 implies success.
/// <p>If the resource does not exist, a Named Resource gives an
/// error (ERUNDEF), while a Process ID Resource gives a return code of 0
/// <p>An optional message may be sent with the signal, and received via WaitMsg.
/// If the first process to receive the signal uses Wait(), the message is discarded.
/// <br>&nbsp;
ClassMethod Signal(ResourceName As %String, Message As %String) As %Integer [ CodeMode = expression ]
{
$system.Event.Signal(ResourceName)
}

/// <p>Clear wakeup events.
/// <p>Sets the number of queued wakeup events for a resource to 0.
/// <p>Resource may be either a Named
/// Resource or a Process ID Resource. If it is a Process ID Resource, the
/// target process' PID is used (i.e. $J of the process to be awakened - which
/// must be an integer value.)
/// <p>A return value of 1 implies success.
/// <p>If the resource does not exist, a Named Resource gives an
/// error (ERUNDEF), while a Process ID Resource gives a return code of 0
/// <br>&nbsp;
ClassMethod Clear(ResourceName As %String) As %Integer [ CodeMode = expression ]
{
$system.Event.Clear(ResourceName)
}

/// <p>Count wakeup events.
/// <p>Resource may be either a Named
/// Resource or a Process ID Resource. If it is a Process ID Resource, the
/// target process' PID is used (i.e. $J of the process to be awakened - which
/// must be an integer value.)
/// <p>The return value is the current count of queued wakeup events for that resource.
/// <p>If the resource does not exist, a Named Resource gives an
/// error (ERUNDEF), while a Process ID Resource gives a return code of -1
/// <br>&nbsp;
ClassMethod Count(ResourceName As %String) As %Integer [ CodeMode = expression ]
{
$system.Event.Count(ResourceName)
}

/// <p>Delete a Named Resource.
/// <p>The Named Resource is deleted and a value
/// of 1 is returned, otherwise 0 is returned.
/// <p>Any processes that were waiting on the resource when it was deleted
/// are awakened with a return code of -1.
/// <br>&nbsp;
ClassMethod Delete(ResourceName As %String) As %Integer [ CodeMode = expression ]
{
$system.Event.Delete(ResourceName)
}

/// <p>Test if a Named Resource has been created.
/// <p>ResourceName is a Named Resource, e.g. 'Lab', '^Queue("main")', etc.
/// <p>Returns 1 if there is a Named Resource by that name, else returns 0.
/// <br>&nbsp;<b></b>
ClassMethod Defined(ResourceName As %String) As %Integer [ CodeMode = expression ]
{
$system.Event.Defined(ResourceName)
}

/// <p>Returns a list of all the Named Resources currently defined.
/// <br>&nbsp;
ClassMethod List() As %List [ CodeMode = expression ]
{
$system.Event.List()
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListExecute ]
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

ClassMethod ListExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Set Node = $increment($$$ISCQUERYTEMP)
	Set events = $system.Event.List()
	For i=1:1:$Listlength(events) {
		Set $$$ISCQUERYTEMP(Node,i)=$ListBuild($List(events,i))
	}
	Set qHandle=Node_"^"
	Quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListExecute ]
{
	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

/// <p>Returns a list of all the Named Resources currently defined.
/// <br>&nbsp;
Query List() As %Query(ROWSPEC = "Event:%String")
{
}

}
