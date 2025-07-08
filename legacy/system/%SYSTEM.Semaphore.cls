/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// Semaphores can be used to control limited access to an application
/// resource locally or across ECP (allowing a limited number of concurrent
/// activities), or can be used to schedule work in the background.</p>
/// <p>
/// <ul>
/// <li>Limit access to an application resource (allow a limited number of
/// concurrent activities) such as running no more than n of certain type
/// of job that uses some resource.<br>
/// <ul>
/// <li>Create a semaphore with initial value equal to the number of concurrent accesses</li>
/// <li>When the resource is required decrement that semaphore.</li>
/// <li>When done with the resource increment the semaphore.</li>
/// <li>When the semaphore value reaches zero decrement will wait until it
/// becomes available.</li>
/// </ul>
/// </li>
/// <li>Schedule work<br>
/// <ul>
/// <li>Create a semaphore with initial value of zero.</li>
/// <li>Start n worker jobs. The worker job should decrement that semaphore (which
/// will wait until it's incremented by any job).</li>
/// <li>When there is work to be done, it should placed the work
/// description in a queue and increment the semaphore.</li>
/// <li>The background worker process decrements the semaphore and
/// dequeues the work that needs to be processed, and does it.</li>
/// </ul>
/// </li>
/// </ul>
/// <p>
/// Semaphores are a shared objects. They can be accessed from multiple jobs.
/// </p>
/// <p>SEMAPHORE NAMES</p>
/// <p>Semaphores are identified by their unique names. If the name starts
/// with ^, %SYSTEM.Semaphore uses the instance global mapping to uniquely
/// identify it (by its system name/number and SFN); otherwise the name is
/// used as is by the instance, independent of namespace and its
/// mappings.</p>
/// <p>
/// Note: The namespace name is stripped from the semaphore name, but the rest is used as is to uniquely identify them. i.e. ^Rem2("22") and ^Rem2(22) are not the same!!
/// </p>
/// <p>
/// If the associated system is a remote node, the remote
/// semaphore is used.</p>
/// <p>
/// Before accessing any of these methods you have to %New and then invoke
/// Open(<sem name>) or Create(<Sem name>, <Initial value>) the
/// semaphore. Both methods return zero if the operation fails. To
/// open/create/access any semaphore with a global name, you must have roles
/// that give write access to the associated database, otherwise these
/// actions will raise a &lt;PROTECT&gt; error.
/// </p>
/// <p>
/// Open will fail if the semaphore does not exist. Create will open the
/// semaphore if it already exists and ignore the initial value.</p>
/// <p>
/// Every semaphore has value, you can get its value by GetValue() or
/// SetValue(<new value>) methods. The value is typed as a 64-bit integer.
/// </p>
/// <p>
/// A semaphore value can be increased via the Increment method by a specified
/// amount.  The amount is given as a positive, 31-bit integer.
/// </p>
/// <p>
/// You can Decrement(&lt;amount to decrement&gt;, &lt;timeout in seconds&gt;)  the
/// semaphore by the specified amount.
/// The amount must be &gt; 0 (the amount is signed 32 bit number).
/// </p>
/// <p>
/// If the value of the semaphore is zero, it will wait the specified
/// amount of time for the amount to be incremented by some other
/// job. While the amount is zero the semaphore will track its requestors
/// by first in first out order.
/// </p>
/// <p>
/// If the amount requested is greater than what is available, it will return the
/// available amount immediately. That is, if there is Decrement(10), but the
/// current available amount is 2, it will return 2. <br>
/// </p>
/// <p>
/// If the Decrement times out, it returns zero. If the time out is zero,
/// it and the Decrement cannot be done, it returns immediately.
/// If the timeout is -1, Decrement will wait forever.
/// </p>
/// <p>
/// If the global is mapped across ECP and the timeout is zero it will
/// wait up to 2 seconds for the ECP response.<br>
/// </p>
/// <p>
/// WAITMANY
/// </p>
/// <p>
/// You can wait for multiple semaphores at once. It's called
/// &quot;WaitMany&quot; support. You specify the amount you wish to
/// decrement to the wait-many list by the AddToWaitMany(&lt;amount to
/// decrement&gt;) instance method of the semaphore object and then you
/// invoke the WaitMany(&lt;timeout in seconds&gt;) class method.
/// </p>
/// <p>
/// When the semaphore is available it invokes/calls-back the
/// WaitCompleted(&lt;granted amount&gt;) method which should be overwritten by
/// the application if using the WaitMany feature. After invoking the
/// WaitCompleted() method, AddToWaitMany must be called again for more
/// amount if it is required.
/// </p>
/// <p>
/// After adding to the WaitMany list, the RmFromWaitMany() method could
/// be used to remove a pending entry, and release the associated
/// resources. Otherwise they will be released when the job halts. If the
/// object has some granted value, and it was removed by the
/// RmFromWaitMany() before the WaitMany() call, the granted amount will
/// be incremented back.
/// </p>
/// <p>WaitMany list is currently limited to 64.</p>
/// <p>
/// WaitMany(&lt;timeout&gt;) does Round Robin notification of pending
/// WaitCompletion notification. After going through the pending grants,
/// it returns with the number of semaphores on which WaitCompleted() was
/// called.
/// </p>
/// <p>Decrement and AddToWaitMany use the same wait queue, and grants are
/// delivered in First-In/First-Out order.</p>
/// <p>
/// Semaphores are a shared object, we can have up to 32K (32,768) of them per
/// instance. Semaphores do not have an owner, and they are not
/// reference-counted. Any object that can open it can delete it using the
/// Delete() method. After deleting, any reference to that semaphore will
/// raise an invalid semaphore error.  If the semaphore is remote, it will
/// delete the semaphore on the server and any reference to that semaphore
/// from any app-server should fail. The WaitMany WaitCompleted method is
/// invoked with a granted value of zero when the semaphore is deleted by
/// a job or by an ECP failure.
/// </p>
/// <p>
/// RECOVERY
/// </p>
/// <p>
/// If a job dies, the allocated resource with a wait-many list is
/// released. But if any amount was granted, it stays granted.  Nothing is returned!</p>
/// <p>
/// ECP
/// </p>
/// <p>
/// If the Semaphore is a remote semaphore, most of the operations and the
/// value are tracked by the ECP server.
///  </p>
/// <p>
/// ECP RECOVERY
/// </p>
/// <p>
/// Remote semaphore operations are not recoverable since the value of
/// the semaphores are not persistent. After any ECP/network outage or
/// failure, all remote semaphores on the app-server are automatically
/// deleted; on the server all pending decrements are
/// dropped/ignored.
/// </p>
/// <p>
/// It is the responsibility of the application to detect and recover the
/// semaphores, by re-creating and setting their initial value(s) and state(s).
/// </p>
/// <p>
/// Ordering considerations:
/// </p>
/// <p>
/// As stated earlier, a global named "^glob" and a semaphore named "^glob" are entirely unrelated.  So in a sequence of commands such as
/// </p>
/// <EXAMPLE LANGUAGE=NONE>
///     set i=$inc(^glob)
///     set ^glob(i)=<value>
///     sem.inc(^glob)
/// </EXAMPLE>
/// <p>
/// the order in which the statements are executed is guaranteed only for a single execution stream.  However, when multiple jobs are involved, the order in which the objects will be manipulated cannot be guaranteed.  It will be the same for each execution stream, but because multiple streams are manipulating shared objects, the order that the objects are changed is unpredictable.
/// </p>
/// <p>i.e. the following order could happen when multiple instances or jobs are involved.</p>
/// <EXAMPLE LANGUAGE=NONE>
/// time    job A           job B
/// 
/// 1   $inc returns 1
/// 2               $inc returns 2
/// 3               set ^glob(2)=<value>
/// 4               sem.inc(^glob)
/// 5   <--- logical state ---->
/// 6   set ^glob(1)=<value>
/// 7   sem.inc(^glob)
/// </EXAMPLE>
/// <p>In the above example at the indicated logical state (at time 5), when sem.inc is delivered in job B,  it's guaranteed that the associated set is there, but there is no guarantee the previous and other $inc and associated data is there!!</p>
/// <p>This would be an issue when multiple nodes or jobs insert a node at the end of a Q using $inc and then they use sem.inc to notify the Q entry's presence. If another global is $inc-ed to find out what to deQ the expected node may not be there.  i.e. @ time 5 if some other global is incremented to deQ, its value would be 1 and if that value is used to reference the Q, ^glob(1) wouldn't be there!!</p>
/// <p>
/// ECP ORDERS &amp; GUARANTEES
/// </p>
/// <p>
/// The following items are guaranteed for remote semaphores:
/// <ul>
/// <li>Increment(s) will happen after sets and kills.</li>
/// <il>The semaphore grants do not honor durability as locks do. When a
/// lock is granted, any data before the lock grant is durable; this is
/// NOT true for semaphores.</li>
/// <li>When a semaphore is granted the data cache is guaranteed to be
/// coherent relative to Increment().</li>
/// </ul>
/// </p>
/// 
Class %SYSTEM.Semaphore Extends %Library.SystemBase
{

Parameter %MODULENAME [ Internal ] = 3;

Parameter %MODULEBASECLASS [ Internal ] = "ISC_method_dispatcher, public invalidateMths";

/// Internal semaphore ID
/// 
Property SemID As %Integer [ Internal, Private ];

/// Multi wait list index
/// 
Property WaitIdx As %Integer [ Internal, Private ];

/// <p>
/// Initializes this object. It must be called before
/// accessing any of its methods. The initial value is set to the
/// specified amount.  It returns zero on failure.
/// </p>
/// 
Method Create(name As %Binary, value As %CPP.LongLong = 0) As %Integer [ Language = cpp ]
{
}

/// <p>
/// Initialize a pre-existing semaphore. It must be
/// called before accessing any of the semaphore methods.
/// Returns zero on failure.
/// </p>
/// 
Method Open(name As %Binary) As %Integer [ Language = cpp ]
{
}

/// <p>
/// Semaphores are shared objects and they do not go away until they
/// are deleted explicitly. After deletion, any references to this object from the
/// current job or any other job will fail. If the semaphore is remote, it deletes
/// the semaphore on the remote system too.
/// </p>
/// 
Method Delete() As %Integer [ Language = cpp ]
{
}

/// <p>
/// Returns the current value storedin the semaphore.
/// </p>
/// 
Method GetValue() As %CPP.LongLong [ Language = cpp ]
{
}

/// <p>
/// Sets the current sempahore value to the specified amount.
/// </p>
/// 
Method SetValue(amount As %CPP.LongLong) [ Language = cpp ]
{
}

/// <p>
/// Increments the semaphore by the specified amount.
/// </p>
/// 
Method Increment(value As %Integer) [ Language = cpp ]
{
}

/// <p>
/// If the requested amount is not available (available amount is less than the requested amount), it will decrement by the available amount, setting it
/// to zero.
/// </p>
/// <p>
/// If the semaphore value is zero, this method waits for the specified
/// timeout in seconds; a value of -1 means "wait forever".
/// If the timeout period expires and no increments have been made to the
/// semaphore,
/// this method returns 0.
/// </p>
/// <p>
/// Otherwise, the method returns the amount decremented.
/// </p>
/// 
Method Decrement(amount As %Integer, timeout As %Integer) As %Integer [ Language = cpp ]
{
}

/// <p>
/// Add this semaphore to the wait-many list with the specified amount
/// to decrement. This method uses the Decrement() method rules. It
/// decrements in the background as soon as the semaphore value is great
/// enough. Note: the completion code is delivered by the WaitMany()
/// method.
/// </p>
/// 
Method AddToWaitMany(value As %Integer) [ Language = cpp ]
{
}

/// <p>
/// Remove this semaphore from the wait-many list. The WaitMany() list
/// caches the associated objects. This method must be called before
/// closing this object so it can be properly removed from the cache,
/// otherwise the object's reference count will never drop to zero and it
/// will not get destroyed.
/// </p>
/// 
Method RmFromWaitMany() [ Language = cpp ]
{
}

/// <p>
/// Wait for multiple semaphores. It waits for all semaphores
/// registered in the WaitMany list. It waits the specified amount of time in
/// seconds. It returns 0 if it times out, or returns the number of sempahores that were
/// granted.
/// </p>
/// <p>
/// If the timeout is zero, it just polls all sempahores, and invokes the
/// WaitCompleted methods of all available semaphores.
/// Note: It invokes the WaitCompleted() method in a round robin order.
/// </p>
/// 
ClassMethod WaitMany(timeout As %Integer) As %Integer [ Language = cpp ]
{
}

/// <p>
/// This method is invoked by the WaitMany() class method when the
/// requested amount of semaphores are decremented. After invoking this method,
/// the semaphore is removed from the wait-many list. An explicit invocation of
/// AddToWaitMany is required to put it back on the wait-many list.  If the associated
/// semaphore is deleted and it was in the wait list, this method is called with
/// a granted amount of zero.</p>
/// <p>
/// Note: this class is an abstract class and the derived sub-class must
/// overwrite this method before any of the wait-many features can be
/// used.
/// </p>
/// 
Method WaitCompleted(value As %Integer) [ Language = cpp ]
{
}

}
