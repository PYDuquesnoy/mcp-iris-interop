/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class contains special runtime functions for interacting with ECP. 
/// The management-related API is found in <CLASS>SYS.ECP<CLASS>.
Class %SYSTEM.ECP Extends Help [ Abstract, System = 4 ]
{

/// Forces synchronization of this application server's cache with the data server.
/// This method can be used in special cases where an application requires 
/// the latest data to be visible without the use of normal synchronization
/// mechanisms such as locking.
/// <p>
/// Upon successful completion, all updates from this application server will be
/// visible on the data server, and any updates visible on the data server 
/// as of the time of the Sync request will be visible on this application server. 
/// Note that the data made visible is <b>not</b> guaranteed to be durable on disk. 
/// For more info, see <i>ECP Recovery Guarantees and Limitations</i> in the 
/// <i>Distributed Data Management Guide</i>, "Dirty Data Reads without Locking"
/// limitation.  Due to the "ECP Lock Guarantee", the Sync method is not typically
/// needed.  
/// <p>
/// As an example, consider a scenario where process A inserts data and then sends
/// a message to process B.  Upon receiving the message, process B expects to read
/// the data inserted by A.  The Sync method can be used to ensure that B can see
/// the data set by A as follows.  Process A calls Sync after inserting the data
/// and before sending the message; Process B calls Sync after receiving the 
/// message and before accessing the data.
/// <p>
/// In the example scenario given, if <b>any</b> of the following conditions apply,
/// the Sync call is <b>not</b> needed:
///  <li>If locks are used to coordinate access to the data in question, then Sync
/// is not needed (due to the "ECP Lock Guarantee").
///  <li>If Processes A and B both run on the same application server (or on the
/// data server) Sync is not needed.  Updates are always visible on the server where
/// they originated.
///  <li>If the message from A to B is itself stored on the data server, for
/// example by A setting a message into a global and B polling that global, then
/// the Sync is not necessary.  If B can see the message in the database, it can
/// also see the data that A set the message global (the "In-Order Updates
/// Guarantee").
/// <p>
/// Additionally, in the example above, if either process is running on the data
/// server itself, then that process does not need to issue its Sync call.  
/// <p>
/// <b>Parameters:</b><br>
/// (Optional) The connection index for the data server to be synchronized.
/// Call with no parameters to synchronizes this application server with all
/// connected data servers (or the only data server in the case of a single data
/// server). The connection index for a configured server can be found by name
/// via <METHOD>GetClientIndex</METHOD>.
/// <p>
/// <b>Return Value:</b><br>
/// Returns the number of servers synchronized.  If a server connection is not yet
/// established, then it will not be synchronized.  However, since it will
/// implicitly synchronize on connecting, the return value can typically be
/// ignored.  Throws &ltFUNCTION&gt if an invalid connection index is specified.
/// 
ClassMethod Sync(index As %Integer) As %Integer
{
}

/// Given the data server connection name configured on this client, returns a numeric index for use in other ECP client-side methods.
/// Returns -1 if not found.
/// 
ClassMethod GetClientIndex(servername As %String) As %Integer
{
}

}
