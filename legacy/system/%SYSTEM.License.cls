/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%LMF, %sySite, %syINET, %sySystem, %syPidtab, %ems)

/// The %SYSTEM.License class provides an interface to the InterSystems IRIS License API.
/// <br> <br>
/// Some class methods are implemented in the special $system object and can be accessed with the $SYSTEM.License.Method() syntax.
/// The system object methods are identified in the method documentation as $SYSTEM.License.XXX.
/// <br> <br>
///      Example:  Set Success=$SYSTEM.License.Login(UserIdentifier)
/// <br><br>
/// Other methods are implemented as class methods of the %SYSTEM.License class and can be accessed by the usual
/// ##class(%SYSTEM.License).ClassMethodName() syntax.  The special $system object methods can also be accessed in this way. 
/// <br><br>
///      Example:  Do ##class(%SYSTEM.License).ShowSummary()
/// <br><br>
/// The %SYSTEM.License class includes a number of license usage reports and queries.  
/// The data source is either the local instance or the license server, or in some cases both.
/// The data source is identified in the individual query descriptions.<br><br>
/// Comparing data from the license server with data from an individual InterSystems IRIS instance can sometimes lead to apparent inconsistencies.
/// These inconsistencies can be explained by understanding the operation of the license server.
/// Each InterSystems IRIS instance maintains a database of its license use and independently controls connections to itself.
/// When multiple instances share a InterSystems IRIS license key, the license server coordinates the counting of license usage among all instances sharing the license key.
/// Each instance periodically sends messages to the license server describing any changes that have occurred to the local license database since the previous message.
/// Each instance controls logins and logouts locally and can continue to permit connections if communication with the license server should be interrupted.
/// The license server coordinates the activity of the participating instances by preventing them from collectively exceeding the authorized license count.
/// <br><br>The periodic nature of license server updates is one source of temporary inconsistency between the license server's view of license use and an individual InterSystems IRIS instance's view.  
/// License server and InterSystems IRIS instance counts of license usage will be temporarily out of sync if a number of logins or logouts have not yet been sent to the license server at the time usage reports are requested from the license server and from the local instance.
/// This inconsistency is short lived because updates are sent to the license server about every 15 seconds.
/// <br><br>It is also possible for the active license server to be stopped, perhaps because the host on which it is running has shut down or because the instance that started it is being upgraded.
/// In this case, the replacement license server's view of license use will be incomplete until all participating instances have reported their license use. 
Class %SYSTEM.License Extends %SYSTEM.Help [ Abstract, Final, System = 4 ]
{

/// Signal the License Monitor (^LMFMON) to check for a new key from the License Server,
/// and download and upgrade to that key if there is one.
/// This is normally done every 5 minutes by the Monitor, but this method can make it check immediately. 
/// <br>A return of -1 means that no LicenseID was found.
/// <br>A return of 1 means the signal was successful, a return of 0 means the signal was not successful.
/// <br>The latest key downloaded can be checked in the Portal License Key page.
ClassMethod CheckNewKey() As %Integer
{
}

/// Upgrade to a license (iris.key file) that has been copied to the mgr directory.
/// In some cases the license key will not be upgraded or may be incompletely upgraded.
/// Upgrades may not activate all additional license units if they are unable to allocate sufficient memory from the shared memory heap.
/// Upgrades to a key with fewer license units will be deferred until the InterSystems IRIS instance is restarted.
/// Upgrades to or from a "Power Unit" key will be deferred until the InterSystems IRIS instance is restarted.
/// <br> Return value is 1 on success, "0|Reason for failure" on failure.
/// <br> The failure message may refer you to messages.log for additional information.
ClassMethod Upgrade() As %String [ Final ]
{
}

/// Check the input license key parameter values and, if they are valid, write a license file using thise parameters.
/// LicenseCapacity, CustomerName, OrderNumber, ExpirationDate, AuthorizationKey, and MachineID are the fields of the InterSystems IRIS portion of the key.
/// AppNames is a comma separated list of applications.  For now, this is limited to "TrakCare".
/// AppLicense is the application section of the key formatted as:  Label=value$c(13,10)Label=value$c(13,10)...
ClassMethod SaveLicenseKey(LicenseCapacity As %String, CustomerName As %String, OrderNumber As %String, ExpirationDate As %String, AuthorizationKey As %String, MachineID As %String = "", AppNames As %String = "", AppLicense As %String) As %Status [ Final, Internal ]
{
}

/// Specify Deferred (usage=1) or automatic (usage=0) license login for the local InterSystems IRIS instance.
ClassMethod DeferUserIdentification(usage As %Integer) As %Integer [ Final ]
{
}

/// Dump all the local InterSystems IRIS instance's license table entries to 'filename' in the sequential file output directory. A file named all.dmp is created if the filename argument is not supplied.<br>
/// The report displays the following columns:<br>
/// <ul><li>UserId:  the license user identifier consuming each license table entry.</li>
/// <li>Type:  License login type (User, CSP, or Mixed)</li>
/// <li>Connections:  Number of connections to this instance by this user.</li>
/// <li>MaxCon:  Maximum number of connections to this instance by this user.</li>
/// <li>CSPCon:  Number of CSP connections by this user.</li>
/// <li>LU:  Number of license units consumed.  If more than one, the maximum connection count is or was exceeded by this user and the user is now consuming one license unit per connection.</li>
/// <li>Active:  Time in seconds the user has been active.</li>
/// <li>Grace:  Number of seconds remaining in the grace period for a CSP user who has disconnected.</li></ul>
/// This report shows license use at the local instance and is identical to the report produced by ldumpall^%SYS.LICENSE.  It presents the results of the %SYSTEM.License.UserListAll query.
/// 
ClassMethod DumpLocalAll(filename As %String) As %String [ Final ]
{
}

/// Dump the local InterSystems IRIS instance's active license table entries to 'filename' in the sequential file output directory.  A file named inuse.dmp is created if the filename argument is not supplied.<br>
/// The report displays the following columns:<br>
/// <ul><li>UserId:  the license user identifier consuming each license table entry.</li>
/// <li>Type:  License login type (User, CSP, or Mixed)</li>
/// <li>Connections:  Number of connections to this instance by this user.</li>
/// <li>MaxCon:  Maximum number of connections to this instance by this user.</li>
/// <li>CSPCon:  Number of CSP connections by this user.</li>
/// <li>LU:  Number of license units consumed.  If more than one, the maximum connection count is or was exceeded by this user and the user is now consuming one license unit per connection.</li>
/// <li>Active:  Time in seconds the user has been active.</li>
/// <li>Grace:  Number of seconds remaining in the grace period for a CSP user who has disconnected.</li></ul>
/// This report shows license use at the local instance and is identical to the report produced by ldumpinuse^%SYS.LICENSE.  It presents the results of the %SYSTEM.License.UserList query.
/// 
ClassMethod DumpLocalInUse(filename As %String) As %String [ Final ]
{
}

/// Dump license use by process Id to 'filename' in the sequential file output directory.  A file named piduse.dmp is created if the filename argument is not supplied.<br>
/// The report displays the following columns:<br>
/// <ul><li>PID:  Process Id.</li>
/// <li>Display PID:  Process Id in display format (hex on VMS).</li>
/// <li>Process:  Process type (System, User, CSP, Diagnostic, Server, Pending).</li>
/// <li>LID:  The license user identifier for which a license unit is being consumed.</li>
/// <li>Type:  License login type (User, CSP, or Mixed)</li>
/// <li>Con:  Number of connections to this instance by this user.</li>
/// <li>MaxCon:  Maximum number of connections to this instance by this user.</li>
/// <li>CSPCon:  Number of CSP connections by this user.</li>
/// <li>LU:  Number of license units consumed.  If more than one, the maximum connection count is or was exceeded by this user and the user is now consuming one license unit per connection.</li>
/// <li>Active:  Time in seconds the user has been active.</li>
/// <li>Grace:  Number of seconds remaining in the grace period for a CSP user who has disconnected.</li></ul>
/// This report shows license use at the local instance and is identical to the report produced by ldumppid^%SYS.LICENSE.  Summing the columns of this report is meaningless.<br>
/// This report is identical to ldumppid^%SYS.LICENSE.  It presents the results of the %SYSTEM.License.ProcessList query.
/// 
ClassMethod DumpLocalPID(filename As %String) As %String [ Final ]
{
}

/// Process a query for DumpLocal[All/Inuse/PID] reports and write the report to a file.
/// Query: is the name of the query to process.
/// filename: is the filename into which to output the report.
ClassMethod DumpLocalWork(query As %String, filename As %String) As %String [ Internal, Private ]
{
}

/// Dump License Server database for this server.
/// <br>Note:  Not applicable with a Single-Server key.
/// This report presents license usage by the current InterSystems IRIS instance recorded at the license server.  The report is produced by the license server and may reside on a remote host.  The location (host and directory) of the report output file will be reported to the terminal when the report is complete."
/// License use by client (License Id) is reported in these columns:<br>
/// <ul><li>Connections:  Number of connections for this client.</li>
/// <li>License Units:  Number of license units consumed by this client on this server.</li>
/// <li>Client:  License Id consuming the license unit or units.</li>
/// </ul>
/// The report summarizes total connections and license units consumed by clients attached to this InterSystems IRIS instance and the total number of license units shared by clients on this the InterSystems IRIS server instance with connections by the same client to other the InterSystems IRIS server instances.
/// This report is identical to that produced by dumpserver^%SYS.LICENSE.
ClassMethod DumpServer() [ Final ]
{
}

/// Dump License Server database for all servers.
/// <br>Note:  Not applicable with a Single-Server key.<br> 
/// <br>This report presents license usage by each InterSystems IRIS instance served by the license server.  The report is produced by the license server and may reside on a remote host.  The location (host and directory) of the output file will be displayed on the terminal when the report is complete.
/// License use by client (License Id) is reported in these columns:<br>
/// <ul><li>Connections:  Number of connections for this client.</li>
/// <li>License Units:  Number of license units consumed by this client on this server.</li>
/// <li>Client:  License Id consuming the license unit or units.</li>
/// </ul>
/// The report summarizes total connections and license units consumed by clients connected to each InterSystems IRIS instance and the number of license units shared by clients connected to this the InterSystems IRIS server instance with connections from the same client to other the InterSystems IRIS server instances.
/// A combined grand total of connections and license units consumed by all the InterSystems IRIS server instances served by the license server is reported.
/// This report is identical to that produced by dumpservers^%SYS.LICENSE.
ClassMethod DumpServers() [ Final ]
{
}

/// Dump the License Server view of key utilization for the active key.
/// <br>Note:  Not applicable with a Single-Server key.<br>
/// <br>This report displays license utilization for the key loaded by the current InterSystems IRIS instance.  The report is produced by the license server and may reside on a remote host.  The location (host and directory) of the output file will be displayed on the terminal when the report is complete.
/// The report shows the license server's view of license use by all InterSystems IRIS instances which share a license key and which are configured to use the same license server (as is required when sharing a key).
/// <br><br>License use by each client (License Id) connected to each InterSystems IRIS instance is reported in these columns:<br>
/// <ul>
/// <li>Client:  License Id for the connection from a client to this InterSystems IRIS instance.</li>
/// <li>LU:  Number of license units consumed by connections from this client to this InterSystems IRIS instance.</li>
/// <li>Connections:  Number of connections from this client to this InterSystems IRIS instance.</li>
/// <li>Server:  Address of host where the InterSystems IRIS instance is running.</li>
/// <li>Instance:  Name of the InterSystems IRIS instance to which the client is connected.</li>
/// </ul>
/// The report displays the fields of the license key and summarizes the number of servers (InterSystems IRIS instances) using the key, authorized license units, and the current and maximum number of license units in use.  This summary information represents the license server's view of license use.
/// This report is identical to the report produced by dumpkey^%SYS.LICENSE.
ClassMethod DumpKey() [ Final ]
{
}

/// Dump the License Server view of key utilization for all keys.
/// <br>Note:  Not applicable with a Single-Server key.<br>
/// <br>This report displays license utilization for every key controlled by the license server.  The report is produced by the license server and may reside on a remote host.  The location (host and directory) of the output file will be displayed on the terminal when the report is complete.
/// The report shows the license server's view of license usage by all InterSystems IRIS instances which share each license key under the license server's control.  For true reporting and as a requirement of the InterSystems IRIS license agreement, each InterSystems IRIS instance that uses a key must configure the same set of license servers.
/// <br><br>License use by each client (License Id) connected to each InterSystems IRIS instance is reported in these columns:<br>
/// <ul>
/// <li>Client:  License Id for the connection from a client to this InterSystems IRIS instance.</li>
/// <li>LU:  Number of license units consumed by connections from this client to this InterSystems IRIS instance.</li>
/// <li>Connections:  Number of connections from this client to this InterSystems IRIS instance.</li>
/// <li>Server:  Address of host where the InterSystems IRIS instance is running.</li>
/// <li>Instance:  Name of the InterSystems IRIS instance to which the client is connected.</li>
/// </ul>
/// The report displays the fields of each license key and summarizes the number of servers (InterSystems IRIS instances) using the key, authorized license units, and the current and maximum number of license units in use.  This summary information represents the license server's view of license use for each license key.
/// This report is identical to the report produced by dumpkeys^%SYS.LICENSE.
ClassMethod DumpKeys() [ Final ]
{
}

/// Display Summary of License Server Database.
/// <br>Note:  Not applicable with a Single-Server key.
/// <br><br>Displays a summary of license use for the current InterSystems IRIS instance's active license key.  The report displays license usage data obtained both from the license server and from the local InterSystems IRIS instance.
/// <br><br> The distributed license use section summarizes license use by all InterSystems IRIS instances that share the key.  The license server is the source of this information.
/// <ul>
/// <li>Current License Units Used:  current number of license consumed by all InterSystems IRIS instances sharing this key.</li>
/// <li>Maximum License Units Used:  maximum number of license consumed by all InterSystems IRIS instances sharing this key at any time since the license server started.</li>
/// <li>License Units   Authorized:  number of license units authorized by the installed license key file.</li>
/// </ul>
/// The local license use section summarizes license use by the InterSystems IRIS instance where the report is run.  The source of this section is the local InterSystems IRIS instance's internal license use tables.
/// <ul>
/// <li>Current Connections:  The current number of connections (license logins) to the local InterSystems IRIS instance.</li>
/// <li>Maximum Connections:  The maximum number of connections (license logins) to the local InterSystems IRIS instance since it started.</li>
/// <li>Current Users:  The current number of license units consumed on the local InterSystems IRIS instance.  Note that this item displays license units, not distict users.</li>
/// <li>Maximum Users:  The maximum number of license units consumed on the local InterSystems IRIS instance since it started.</li>
/// </ul>
/// This report is identical to the report produced by ShowSummary^%SYS.LICENSE.  It presents the results of the %SYSTEM.License.ShowSummary query.
ClassMethod ShowSummary() [ Final ]
{
}

/// Display current active license Server address and port.
/// <br>Note:  Not applicable with a Single-Server key.
/// OBSOLETE - USE ShowServer 
ClassMethod ShowManager() [ Final, Internal ]
{
}

/// Display current active license Server address and port.
/// <br>Note:  Not applicable with a Single-Server key. 
/// <br> This report is identical to the report produced by ShowServer^%SYS.LICENSE.
ClassMethod ShowServer() [ Final ]
{
}

/// Display Local view of license use.<br><br>
/// This report summarizes information derived from the current InterSystems IRIS instance's local license utilization database.
/// <ul><li>Total Authorized LU:  license units authorized by the installed license file.</li>
/// <li>Current Available LU:  License units available at the local InterSystems IRIS instance.</li>
/// <li>Minimum Available LU:  Minimum number of license units availible since the local instance started.</li>
/// <li>Current Users active:  Number of distinct users logged in to the local instance.  May be less than the difference between total authorized and current available license units if one or more users have exceeded MaxConnections.</li>
/// <li>Maximum Users active:  Maximum number of distinct users logged in to the local instance at any time since it started.</li>
/// <li>Current CSP Users active:  Current number of CSP sessions consuming license units at the local InterSystems IRIS instance.</li>
/// <li>Maximum CSP Users active:  Maximum number of CSP sessions consuming license units at any time since the local InterSystems IRIS instance started.</li>
/// <li>Current CSP Sessions in grace period:  Current number of CSP sessions in grace period on the local InterSystems IRIS instance.</li>
/// <li>Maximum CSP Sessions in grace period:  Maximum number of CSP sessions in grace period at any time since the local InterSystems IRIS instance started.</li>
/// </ul>
/// <br>This report is identical to the report produced by counts^%SYS.LICENSE. It presents the results of the %SYSTEM.License.Counts query.
/// 
ClassMethod ShowCounts() [ Final ]
{
}

/// Decode and display the capabilities encoded in the AuthorizationKey field of the active License Key.<br><br>
/// 
ClassMethod Decode() [ Final ]
{
}

/// Decode and display the capabilities encoded in the AuthorizationKey field of a License Key provided as the 'key' argument.
ClassMethod DecodeAuth(key As %String) [ Final ]
{
}

/// Display the active license key to the current device.<br>
/// The fields of the [License] section of the installed license file
/// are displayed followed by a brief accounting of license usage, including:<br>
/// <ul><li>License units currently available.</li>
/// <li>Minimum number of license units available at any time since the instance started.</li>
/// <li>Maximum number of license units available.</li></ul>
/// License usage levels are obtained from the current InterSystems IRIS instance.<br>
/// This report is identical to those produced by CKEY^%SYS.LICENSE and ^CKEY.
ClassMethod CKEY() [ Final ]
{
}

/// Fetch license key status:  Valid, Invalid, or Troubled (expiring).
ClassMethod GetKeyStatus() [ Final ]
{
}

/// Fetch string describing the reason the key is invalid or in a troubled state.
ClassMethod GetKeyInvalidReason() [ Final ]
{
}

/// $$SYSTEM.License.MaxBufferPool() returns the maximum buffer pool size authorized by the active license key.  Zero indicates unlimited.
ClassMethod MaxBufferPool() As %Integer
{
}

/// $SYSTEM.License.MaxDB() returns the maximum number of Databases authorized by the active license key.  Zero indicates unlimited.
/// Passing 'UserOnly' = 1 will return the nuber of non-system Databases authorized (system "overhead" is subtracted).  
ClassMethod MaxDB(UserOnly As %Boolean = 0) As %Integer
{
}

/// $SYSTEM.License.MaxConnections() returns the maximum number of connections a user can make while consuming one license unit.
ClassMethod MaxConnections() As %Integer
{
}

/// $SYSTEM.License.MaxCSPUsers() returns the maximum number of concurrent CSP users since the instance started or the CSPUsers maximum counter was reset.
ClassMethod MaxCSPUsers() As %Integer
{
}

/// $SYSTEM.License.MaxCSPGrace() returns the maximum number of CSP sessions in the grace period at any time since the instance started or the CSPGrace maximum counter was reset.
ClassMethod MaxCSPGrace() As %Integer
{
}

/// $SYSTEM.License.CSPUsers() returns the current number of CSP users.
ClassMethod CSPUsers() As %Integer
{
}

/// $SYSTEM.License.CSPGrace() returns the current number of CSP sessions in the grace period.
ClassMethod CSPGrace() As %Integer
{
}

/// $SYSTEM.License.MaxECPServers() returns the maximum number of ECP servers authorized by the active license key.
ClassMethod MaxECPServers() As %Integer
{
}

/// $SYSTEM.License.NetworkEnabled() returns 1 if the InterSystems IRIS license key enables ECP, 0 if it doesn't.
ClassMethod NetworkEnabled() As %Integer
{
}

/// $SYSTEM.License.ConnectionCount() returns the number of connections currently associated with the given UserIdentifier.  
/// The range of return values is normally 0 through MAXCONNECTIONS.  
/// If the value exceeds MAXCONNECTIONS then more than the allowable number of concurrent connections were attempted for a given ID and the system has transitioned to a mode of one connection per license for this UserIdentifier.
ClassMethod ConnectionCount(UserIdentifier As %String) As %Integer
{
}

/// $SYSTEM.License.LicenseCount() returns the number of License Units currently consumed on the local instance by the given UserIdentifier.  
/// The return value is usually 0 if the UserIdentifier is not licensed or 1 if it is.    
/// However, if the maximum number of connections has ever exceeded MAXCONNECTIONS 
/// (the maximum allowed number of concurrent connections for a single license) for this UserIdentifier, 
/// the system has transitioned to a mode of one license per connection for this UserIdentifier and the return value will be the current number of connections by UserIdentifier.
ClassMethod LicenseCount(UserIdentifier As %String) As %Integer
{
}

/// $SYSTEM.License.CheckAppLicenseUsed(AppName,Keyword) iterates through the internal license use tables counting the number of times an application license keyword has been taken.
/// The resulting count is compared to the internal usage count maintained for the application license keyword.  The internal count is adjusted if it does not agree with the counted value.<br>
/// The return value is a string containing "CountedUsage,InternalUsageCountBeforeAdjustment,AppLicensesRecovered"<br>
/// Throws an "INVALID ARGUMENT" error if AppName is not licensed.  Returns "" if FeatureKeyword is not licensed.  Returns "" if the application/keyword license value is not a number because only numeric application features can be taken and released.
/// AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.
/// <br><br>Example:  $SYSTEM.License.CheckAppLicenseUsed("MyCompany.MyApp","MyAppFeature")
ClassMethod CheckAppLicenseUsed(AppName As %String, FeatureKeyword As %String) As %String [ Final ]
{
}

/// $SYSTEM.License.GetAppLicense(AppName) retrieves the application license for the named application as a string of Keyword=Value pairs separated by $c(0), terminated by an empty $C(0) piece.
/// AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections or the TrakCare application.
/// <br> If GetValues is zero, only the keyword names are returned.  If GetValues is not zero, a sequence of kw=value are returned.
/// <br><br>Example:  $SYSTEM.License.GetAppLicense("MyCompany.MyApp",1)
/// <br><br> Example return value:  "kw1=value1"_$c(0)_"kw2=value2"_$c(0)_..._"kwN=valueN"_$c(0)_$c(0)
ClassMethod GetAppLicense(AppName As %String, GetValues As %Integer = 0) As %String [ Final ]
{
}

/// $SYSTEM.License.GetAppLicenseUsed(AppName,Keyword) retrieves the number of consumed license units associated with an application license keyword.
/// <br>AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.  Keyword is the keyword of the application feature.
/// <br>GetAppLicenseUsed() is only meaningful where the value associated with the keyword is numeric.
/// <br> An INVALID ARGUMENT error is returned if no application license is loaded for "AppName".  An empty string is returned if "Keyword" is not a feature of "AppName". 
/// <br><br>Example:  $SYSTEM.License.GetAppLicenseUsed("MyCompany.MyApp","MyAppFeature")
ClassMethod GetAppLicenseUsed(AppName As %String, FeatureKeyword As %String) As %String [ Final ]
{
}

/// $SYSTEM.License.GetAppLicenseMaxUsed(AppName,Keyword) retrieves the maximum number of consumed license units associated with an application license keyword, since the license was loaded.
/// <br>AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.  Keyword is the keyword of the application feature.
/// <br>GetAppLicenseMaxUsed() is only meaningful where the value associated with the keyword is numeric.
/// <br> An INVALID ARGUMENT error is returned if no application license is loaded for "AppName".  An empty string is returned if "Keyword" is not a feature of "AppName". 
/// <br><br>Example:  $SYSTEM.License.GetAppLicenseMaxUsed("MyCompany.MyApp","MyAppFeature")
ClassMethod GetAppLicenseMaxUsed(AppName As %String, FeatureKeyword As %String) As %String [ Final ]
{
}

/// $SYSTEM.License.GetAppLicenseValue(AppName,Keyword) retrieves the value associated with an application license keyword.<br>
/// AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.  Keyword is the keyword of the application feature.
/// <br> An INVALID ARGUMENT error is returned if no application license is loaded for "AppName".  An empty string is returned if "Keyword" is not a feature of "AppName". 
/// <br><br>Example:  $SYSTEM.License.GetAppLicenseValue("MyCompany.MyApp","MyAppFeature")
ClassMethod GetAppLicenseValue(AppName As %String, FeatureKeyword As %String) As %String [ Final ]
{
}

/// $SYSTEM.License.GetAppLicenseFree(AppName,Keyword) retrieves the number of free license units associated with an application license feature keyword.
/// AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.  Keyword is the keyword of the application feature.
/// <br>GetAppLicenseFree() is only meaningful where the value associated with the keyword is numeric.
/// <br> An INVALID ARGUMENT error is returned if no application license is loaded for "AppName".  An empty string is returned if "Keyword" is not a feature of "AppName". 
/// <br><br>Example:  $SYSTEM.License.GetAppLicenseFree("MyCompany.MyApp","MyAppFeature")
ClassMethod GetAppLicenseFree(AppName As %String, FeatureKeyword As %String) As %String [ Final ]
{
}

/// $SYSTEM.License.GetAppLicenseMinimum(AppName,Keyword) retrieves the minimum number of free license units associated with an application license keyword.
/// AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.  Keyword is the keyword of the application feature.
/// <br>GetAppLicenseMinimum() is only meaningful where the value associated with the keyword is numeric.
/// <br> An INVALID ARGUMENT error is returned if no application license is loaded for "AppName".  An empty string is returned if "Keyword" is not a feature of "AppName". 
/// <br><br>Example:  $SYSTEM.License.GetAppLicenseMinimum("MyCompany.MyApp","MyAppFeature")
ClassMethod GetAppLicenseMinimum(AppName As %String, FeatureKeyword As %String) As %String [ Final ]
{
}

/// $SYSTEM.License.GetAppNames(AppTypes) returns a list of licensed applications.<br>
/// AppTypes is a string containing the type[s] of licensed applications which should be returned.
/// <ul><li>"I":  Return InterSystems supplied applications.</li>
/// <li>"P":  Return protected applications loaded from the license file.</li>
/// <li>"U": Return unprotected applications loaded with the $SYSTEM.License.LoadAppLicenseFile() method.</li></ul>
/// Set Applications=$SYSTEM.License.GetAppNames("PU") ;Fetch all non InterSystems licensed application names.
ClassMethod GetAppNames(AppTypes As %String) As %List
{
}

/// $SYSTEM.License.GetProcessAppsTaken(AppName,Keyword) retrieves a $List of application license types taken for the Process PID or "" for none.
/// PID specifies the process. AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.
/// <br> An INVALID ARGUMENT error is returned if no application license is loaded for "AppName".
/// <br><br>Example:  $SYSTEM.License.GetProcessAppsTaken($J,"MyCompany.MyApp")
ClassMethod GetProcessAppsTaken(PID As %String, AppName As %String) As %List [ Final ]
{
}

/// $SYSTEM.License.GetConnectionLimit() returns the maximum number of connections permitted per user on this instance.  The limit is established by calling $SYSTEM.License.SetConnectionLimit().  A zero return value means no limit has been set.
ClassMethod GetConnectionLimit() As %Integer
{
}

/// $SYSTEM.License.GetFeature(n) returns 1 if extended license feature n is authorized by the license key, 0 if it is not.
/// <br>
/// <br> Current values of n are:
/// <br> 0) Web Add-on
/// <br> 1) Interoperability
/// <br> 2) Shadowing
/// <br> 3) BI User (runtime)
/// <br> 4) BI Development
/// <br> 5) HealthShare
/// <br> 6) TrakCare
/// <br> 7) IP Address Neutral
/// <br> 8) Analytics Run
/// <br> 9) Analytics Analyzer
/// <br> 10) Analytics Architect
/// <br> 11) NLP
/// <br> 12) HealthShare Foundation
/// <br> 13) C-Type License
/// <br> 14) Analytics VR Execute
/// <br> 15) ExtremeNoUserLimit
/// <br> 16) Analytics VR Format
/// <br> 17) Analytics VR Data Define
/// <br> 18) Sharding
/// <br> 19) IntegratedML
/// <br> 20) InterSystems IRIS
/// <br> 21) API Management
/// <br> 22) Compatibility
/// <br> 23) Security Waiver
/// <br> 24) FHIR Repository
/// <br> 25) Columnar Storage
/// <br> 26) FHIR SQL Builder
/// <br> 27) Foreign Tables
/// <br> 28) Vector Search
ClassMethod GetFeature() As %Integer
{
}

/// $SYSTEM.License.GetUserId() returns the License User Identifier (if any) associated 
/// with the currently executing session/process. 
/// <p>With a Core Capacity license, this method returns the empty string ("") because 
/// InterSystems IRIS does not track license user identifiers.
/// With a user-based license, if this method returns an empty string, that indicates
/// that the session/process is running in a degraded state (as will be the case when 
/// no license has been taken out automatically for the session/process).</p>
/// <p>This method also allows a second argument of JobNumber (the index into the job table), e.g. $SYSTEM.License.GetUserId("",JobNumber).
/// This can be faster than using Process Id if you already have the JobNumber (repeated calls for a single process),
/// or are sequentially accessing all the processes on the system. Note the first argument must be "", and is ignored in this case.</p>
ClassMethod GetUserId(PID As %String, JobNumber As %String) As %String
{
}

/// $SYSTEM.License.GetUserLimit() returns the maximum number of license units the current instance will permit to be consumed.  This is the limit established by a prior call to $SYSTEM.License.SetUserLimit(maxusers) or the number of license units authorized by the license key if no reduced limit has been established.
ClassMethod GetUserLimit() As %Integer
{
}

/// ##class(%SYSTEM.License).IsApplication(AppName) determines whether InterSystems application AppName is licensed or installed on this instance.<br>
/// ##class(%SYSTEM.License).IsApplication(AppName) returns 1 if the the installed key enables AppName, 2 if it does not but AppName is installed, otherwise 0.<br>
/// <br> AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections or for 'TrakCare'.
/// If AppName="*", returns a comma separated list of applications authorized by the key.  Currently, TrakCare is the only known application.
ClassMethod IsApplication(AppName As %String) As %Integer [ Final, Internal ]
{
}

/// ##class(%SYSTEM.License).IsApplicationAuthorizationKey(AppName,AuthorizationKey) determines whether AppName is authorized by the input AuthorizationKey string.<br>
/// ##class(%SYSTEM.License).IsApplicationAuthorizationKey(AppName,AuthorizationKey) returns 1 if the supplied AuthorizationKey string enables AppName, otherwise 0.<br>
/// If AppName="*", returns a comma separated list of applications authorized by the key.  Currently, TrakCare is the only known application.<br>
ClassMethod IsApplicationAuthorizationKey(AppName As %String = "", pak As %String = "") As %Integer [ Final, Internal ]
{
}

/// Answers the question:  Is a there a valid license key in the mgr directory that is not loaded.  Restart may or may not be required.
/// ##class(%SYSTEM.License).IsPendingActivation() returns 1 if the iris.key file in the "mgr" directory is valid but is not the active license key.<br><br>
/// ##class(%SYSTEM.License).IsPendingActivation() returns 0 if the iris.key file in the "mgr" directory is the active license key or if no iris.key file exists in the "mgr" directory or if the key in "mgr" is invalid.
ClassMethod IsPendingActivation() As %Integer
{
}

/// Determine whether the input license key file is valid and if an instance restart will be required to activate it.<br><br>
/// Arguments:<br>
/// PathAndFileName:  (In) Full path to license file.<br>
/// RequiresRestart:  (Out) 1 if instance restart is required to activate key, 0 if not.<br>
/// RestartReason:    (Out) Reason restart is required, or "" if restart is not required.<br><br>
/// Permit:           (In) For internal use only.
/// Return value:<br>
/// $$$OK - key is valid for this platform.<br>
/// Or, error status with explanation of why the key is not valid for this platform.
/// 
ClassMethod IsValidKey(PathAndFileName As %String, ByRef RequiresRestart As %Integer, ByRef RestartReason As %String, Permit As %String = "") As %Status
{
}

/// Copy of IsValidKey for use by EMS.
/// Primarily bypasses most of the system-specific checks, since the key will not
/// actually be loaded/activated on the EMS Manager.
ClassMethod EMSIsValidKey(PathAndFileName As %String, ByRef RequiresRestart As %Integer, ByRef RestartReason As %String, Group As %String) As %Status [ Internal ]
{
}

/// $SYSTEM.License.CheckKeyForUpgrade(NewKeyFile,.Reductions,.Status) compares the active license key with 
/// the key in file NewKeyFile to determine if the new license key authorizes less capability than the active
/// license.
/// It returns TRUE (1) if any capabilities authorized by the active key are absent in the new key or of lessor
/// capacity.  It returns FALSE (0) if all capabilities of the active license are equaled or exceeded by the
/// license in NewKeyFile.
/// <br><br>Arguments:
/// <ul>
/// <li>NewKeyFile (input): full path and file name of new license key file.</li>
/// <li>Reductions (output by reference): an array of capabilities that are smaller in the new key than in the active key.</li>
/// <li>Status (output by reference): an error status returned by IsValidKey when it was called to examine the new license file.</li>
/// </ul>
/// The Reductions array can contain the following elements:
/// <ul>
/// <li>Reductions("Cores")=$lb(OldCores,NewCores)</li>
/// <li>Reductions("Server")=$lb(OldServerValue,NewServerValue)</li>
/// <li>Reductions("Users")=$lb(OldUsers,NewUsers)</li>
/// <li>Reductions("Product")=$lb(OldProduct,NewProduct)</li>
/// <li>Reductions("LicenseType")=$lb(OldType,NewType)</li>
/// </ul>
/// Reductions in licensed features will be indicated by Reductions("Feature", FeatureName)=$lb(OldFeatureValue,NewFeatureValue).
/// License parameters which have not changed or which have increased in capability will not be shown.
ClassMethod CheckKeyForUpgrade(NewKeyFile As %String, ByRef Reductions, ByRef Status As %Status) As %Boolean
{
}

/// Copy of CheckKeyForUpgrade for use by EMS.
/// Primarily bypasses most of the system-specific checks, since the key will not
/// actually be loaded/activated on the EMS Manager.
ClassMethod EMSCheckKeyForUpgrade(NewKeyFile As %String, ByRef Reductions, ByRef Status As %Status, Group As %String) As %Boolean [ Internal ]
{
}

/// Return the number of Cores authorized, given the product and CPU code, and whether Ensemble is enabled, and whether this is a C-Type key.
/// This must yield the same result as s_cpucheck in mcsub.c.
ClassMethod CPUcodeToCoreCount(CPUcode As %Integer, ProductCode As %Integer, IsEnsemble As %Integer, IsCtype As %Integer) As %String [ Final, Internal ]
{
}

/// ##class(%SYSTEM.License).IsAppLicensed(AppName) returns 1 if the application named AppName is licensed, otherwise 0.<br>
/// ##class(%SYSTEM.License).IsAppLicensed(AppName,FeatureKeyword) returns 1 if the feature named FeatureKeyword is licensed for the application named AppName, otherwise 0.<br>
/// <br> AppName is of the form Company.Application for protected application license sections or Application for unprotected application license sections.
/// The license may have been loaded as part of the iris.key file or separately using $system.License.LoadAppLicenseFile()
/// <br><br>Example:  $SYSTEM.License.IsAppLicensed("MyCompany.MyApp","MyAppFeature")
ClassMethod IsAppLicensed(AppName As %String, FeatureKeyword As %String) As %Integer
{
}

/// $SYSTEM.License.Login(UserIdentifier) performs a license login.
/// <br><br>
/// To acquire a license for a particular connection, provide a UserIdentifier (%String).  
/// UserIdentifier can be an arbitrary identifier determined by the application, but it must uniquely identify the user connecting to InterSystems IRIS.  The client IP address will be appended to the identifier provided separated by an "@" sign to form the complete license identifier.
/// If the input string contains an '@' character, the string will be truncated and the client IP address wil be appended following the first '@' character.
/// The UserIdentifier cannot contain the '|' character.  If the '|' character is found, it will be replaced with the forward slash ('/') character.
/// The total length of UserIdentifier can be no more than 64 characters including the '@' character and the IP address appended by the system.  If the input UserIdentifier exceeds 64 characters, $SYSTEM.License.Login will return an ILLEGAL VALUE error.
/// <br> <br>
/// This function will relinquish a license if the session/process is already holding one under a different identifier and it will obtain a new one on the behalf of the user ID provided.
/// <br> <br>
/// If the MAXCONNECTIONS connection limit per user is exceeded, the usual transition to one-license-unit-per-connection will apply to this user identifier.
/// <br> <br>
/// If a failure occurs because no additional license units are available, the session/process will revert to the original license state and the function will return 0.  If the call is successful it will return a positive integer which is the number of connections currently associated with "UserIdentifier@ClientIP" (including the one just consumed).
/// <br> <br>
ClassMethod Login(UserIdentifier As %String) As %Integer
{
}

/// $SYSTEM.License.KeyLicenseCapacity() returns the active key LicenseCapacity field.
ClassMethod KeyLicenseCapacity() As %String
{
}

/// $SYSTEM.License.KeyCustomerName() returns the active key CustomerName field.
ClassMethod KeyCustomerName() As %String
{
}

/// $SYSTEM.License.KeyOrderNumber() returns the active key order number.
ClassMethod KeyOrderNumber() As %Integer
{
}

/// $SYSTEM.License.KeyExpirationDate() returns the active key expiration date as an integer, $H date value.  Use $ZDATE to convert this to readable form.
ClassMethod KeyExpirationDate() As %Integer
{
}

/// $SYSTEM.License.KeyAuthorizationKey() returns the AuthorizationKey field in the active key.
ClassMethod KeyAuthorizationKey() As %String
{
}

/// $SYSTEM.License.KeyFeatures() returns the Features portion of the Authorization field in the active key.
ClassMethod KeyFeatures() As %String
{
}

/// $SYSTEM.License.KeyFileType(IncludeKeyword) returns the FileType property of the [ConfigFile] section of the loaded license key.
/// If the IncludeKeyword argument is 1, the property keyword (FileType=) is included.  If IncludeKeyword is 0, the property keyword is not included.
/// For example, $SYSTEM.License.KeyFileType(1) might return "FileType=InterSystems License Rev-A.1" while  $SYSTEM.License.KeyFileType(0) would return "InterSystems License Rev-A.1".
/// The default value of IncludeKeyword is 0.
ClassMethod KeyFileType(IncludeKeyword As %Integer = 0) As %String
{
}

/// $SYSTEM.License.KeyMachineID() returns the contents of the MachineID field in the active key.
ClassMethod KeyMachineID() As %String
{
}

/// $SYSTEM.License.KeyProduct() returns the active key product (example:  Enterprise).
ClassMethod KeyProduct() As %String
{
}

/// $SYSTEM.License.KeyLicenseType() returns the active key license type (example:  Concurrent User).
ClassMethod KeyLicenseType() As %String
{
}

/// $SYSTEM.License.KeyLicenseUnits() returns the number of license units authorized by the active key.
ClassMethod KeyLicenseUnits() As %Integer
{
}

/// $SYSTEM.License.KeyEnforcedUnits() returns the number of license units enforced by the active key.
ClassMethod KeyEnforcedUnits() As %Integer
{
}

/// $SYSTEM.License.KeyCoresLicensed() returns the number of Cores authorized by the active key.  InterSystems IRIS will not accept a key with a given Cores authorization when running on a host with more cores.
ClassMethod KeyCoresLicensed() As %Integer
{
}

/// $SYSTEM.License.KeyCoresEnforced() returns the number of Cores enforced by the active key.  This may be higher than the number of Cores licensed if an adjustment has been made in the license key.
ClassMethod KeyCoresEnforced() As %Integer
{
}

/// $SYSTEM.License.KeyCPUsLicensed() returns the licensed CPUs code authorized by the active key.  
/// This CPU code is converted to an authorized core count by an algorithim that depends on other aspects of the licensed product.
ClassMethod KeyCPUsLicensed() As %Integer
{
}

/// $SYSTEM.License.KeyCPUsEnforced() returns the licensed CPUs code enforced by the active key.  
/// This CPU code is converted to an authorized core count by an algorithim that depends on other aspects of the licensed product.
/// This number may be higher than the CPUs licensed code if an adjustment has been made in the license key to accomodate a CPU counting issue.
ClassMethod KeyCPUsEnforced() As %Integer
{
}

/// $SYSTEM.License.KeyPlatform() returns the active key licensed platform. 
ClassMethod KeyPlatform() As %String
{
}

/// $SYSTEM.License.KeyServer() returns the active key server type licensed (Single or Multi).
ClassMethod KeyServer() As %String
{
}

/// $SYSTEM.License.KeyVersion() returns the version from the FileType property of the [ConfigFile] section of the loaded license key.  For example, if the [ConfigFile] section containes "FileType=License 2013.1", $SYSTEM.License.KeyVersion() returns 2013.1.
ClassMethod KeyVersion() As %String
{
}

/// $SYSTEM.License.ActiveServerCount() returns the number of instances (including the current instance) currently using the active license key.
/// It executes the $SYSTEM.License.KeyOrderNumber() query and counts the number of instances using a license with the same OrderNumber value as the active license key on the current instance.
/// Error status is returned by reference in the Status argument.
ClassMethod ActiveServerCount(ByRef Status As %Status) As %Integer
{
}

/// ##Class(%SYSTEM.License).ApplicationServerLogin(AppName, Keyword, Status) returns 1 if the number of instances using the
/// active license key used by this instance (including this instance) does not exceed the number authorized by the "Keyword" item in the "AppName" application license section.
/// Error status is returned by reference in the Status argument.
ClassMethod ApplicationServerLogin(AppName As %String = "", Keyword As %String = "", ByRef Status As %Status) As %Integer
{
}

/// $SYSTEM.License.LoadAppLicenseFile(FileName,SectionName)<br>
/// Load a license for the named application into instance memory. 
/// The file is in standard .ini file format and the application license is contained in a 
/// section beginning with [SectionName], where 'SectionName' is the name of the application 
/// licensed by the section. The SectionName value is case sensitive and can contain as many
/// as 47 alphanumeric characters. It cannot contain a period. <br><br>
/// Features licensed are authorized by properties in the application section represented as
/// keyword=value pairs. Keywords are case sensitive and can contain as many as 47 alphanumeric
/// characters. The total length of keyword=value cannot exceed 1024 characters. An application
/// license section can contain 16536 characters including a terminating NULL character
/// appended internally to each keyword=value line. <br><br>
/// Licensed items with a numeric value (6 digits or less) can be counted by the license software
/// (see TakeApplicationLicense() and ReturnApplicationLicense()). Licensed items with a text value
/// can be retrieved with GetAppLicenseValue(AppName,FeatureKeyword). The entire application license
/// can be retrieved with GetAppLicense(AppName,getvalues).
/// <br><br>Example application license section:  <br><br>
/// [MyApplication]<br>
/// Concurrent Users=50<br>
/// LabTech=20<br>
/// Supervisor=3<br>
/// Nurse=50<br>
/// Modules=Lab, Radiology, Billing, Pharmacy<br><br>
/// Arguments:<br>
/// FileName:  file name, including path.  Max 1024 characters.<br>
/// AppName:  application name, the section name containing the application license.  Max 47 characters.
/// <br><br>Return Values:
/// <br>0 = success
/// <br>1 = no file or no section or section is empty or malformed
/// <br>2 = profile section too large
/// <br>4 = cannot allocate (shared) memory for table;
/// <br>5 = keyword or value too long
/// <br>6 = Application name too long.
/// <br><br>Example:  $SYSTEM.License.LoadAppLicenseFile("c:\InterSystems\Licenses\MyIRIS.key","MyApplication")
ClassMethod LoadAppLicenseFile(FileName As %String, AppName As %String) As %Integer
{
}

/// $SYSTEM.License.ReturnApplicationLicense(AppName,FeatureKeyword,.released,session)<br>
/// Return (release) a license unit for an application license and feature.  The license feature value must be numeric in the application license section.
/// Releases the license resource associated with the licensed user Id of the current process, or the session license Id in the case of CSP.<br><br>
/// Arguments:<br>
/// <b>AppName:</b>  The 'Company.Application' value from the section name in iris.key for protected application license sections, or the name of the unprotected application license section loaded with LoadAppLicenseFile().<br><br>
/// <b>FeatureKeyword:</b>  The application feature keyword being released.  If the FeatureKeyword is omitted, the default value is "Concurrent Users".<br><br>
/// <b>Released:</b>  Returns 1 if the license was released, 0 if the license was not held.<br><br>
/// <b>session:</b>  The CSP session Id this application license should be taken for if the application license is being taken for a session, not the current process.  If this argument is not present and %session is defined and is a %CSP.Session object, then the application license will be taken for the %session object.
/// If neither the session argument nor the %session variable is defined, the license is taken for the current process.
/// <br><br>Return value:  $$$OK, or error status.
/// <br>An error status containing an INVALID ARGUMENT error will be returned if no license has been loaded for AppName.
/// <br><br>Example:  $SYSTEM.License.ReturnApplicationLicense("MyCompany.MyApp","MyAppFeature"[[,.Released[, session]])
ClassMethod ReturnApplicationLicense(AppName As %String, FeatureKeyword As %String = "Concurrent Users", ByRef Released As %Integer, session As %CSP.Session) As %Status
{
}

/// $System.License.returnAppLicense(AppName[,FeatureKeyword[,LicenseId]])<br>
/// Return (release) a license unit for an application license item keyword.  The license item value must have been numeric in the application license section.  This method is intended for InterSystems internal use.  Customer code should use $SYSTEM.License.ReturnApplicationLicense)().<br><br>
/// Arguments:<br>
/// AppName:  The 'Company.Application' value from the section name in iris.key for protected application license sections, or the name of the unprotected application license section loaded with LoadAppLicenseFile().<br>
/// FeatureKeyword:  The application keyword being consumed.  If FeatureKeyword is omitted, the default value is "Concurrent Users".<br>
/// LicenseId:  User identifier under which to be licensed.  Used for licensing of CSP sessions.  Non CSP server processes will use the process InterSystems IRIS license id.<br.<br>
/// <br><br>Return value:  0 - license entirely released no license available, positive integer - the number of times this user has taken this license.<br>
/// An INVALID ARGUMENT error will be generated if a license has not been loaded for this application name.
/// <br><br>Example:  $SYSTEM.License.returnAppLicense("MyCompany.MyApp","MyAppFeature",LicenseId)
ClassMethod returnAppLicense(AppName As %String, FeatureKeyword As %String, LicenseId As %String) As %Integer [ Internal ]
{
}

/// $SYSTEM.License.TakeApplicationLicense(AppName,FeatureKeyword,.count,session)<br>
/// Take (consume) a license unit for a named application and feature.  The license feature value must be numeric in the loaded application license section.
/// The InterSystems IRIS license user Id of the current process (or in the case of CSP, the session license Id) will be the user identifier associated with the application license consumed.
/// <br><br>Arguments:
/// <br><br><b>AppName:</b>  The 'Company.Application' value from the section name in iris.key for protected application license sections, or the name of the unprotected application license section loaded with LoadAppLicenseFile().
/// <br><br><b>FeatureKeyword:</b>  The application keyword being consumed.  If the FeatureKeyword is omitted, the default value is "Concurrent Users".
/// <br><br><b>Count:</b>  ByRef argument to receive count of the number of times this user has now taken this application/keyword license.
/// <br><br><b>session:</b>  The CSP session Id this application license should be taken for if the application license is being taken for a session, not the current process.  If this argument is not present, a %session variable is defined and is a %CSP.Session object, then the application license will be taken for the %session object.
/// If neither the session argument nor the %session variable is defined, the license is taken for the current process.
/// <br><br>Return value:  $$$OK, or error status.
/// <br>An error status containing an INVALID ARGUMENT error will be returned if AppName is not licensed.
/// <br>An error status, ERROR #5915: Cannot allocate a license, if the feature is not licensed or its capacity is exhausted.
/// <br><br>An application license can be returned with the $SYSTEM.License.ReturnApplicationLicense(AppName, FeatureKeyword[[, .Count[, session]]) method.  All application licenses taken for a process or a CSP session will be returned automatically when the process exits or the CSP session terminates.
/// <br><br>Example:  $SYSTEM.License.TakeApplicationLicense("MyCompany.MyApp","MyAppFeature",.NewCountTaken)
ClassMethod TakeApplicationLicense(AppName As %String, FeatureKeyword As %String = "Concurrent Users", ByRef Count As %Integer, session As %CSP.Session) As %Status
{
}

/// $System.License.ReturnAllCSPApps(SessionId)<br> Called by the CSP Daemon when it deletes a session object.
ClassMethod ReturnAllCSPApps(session As %CSP.Session) As %Status
{
}

/// $System.License.takeAppLicense(AppName[,FeatureKeyword[,LicenseId]])<br>
/// Take (consume) a license unit for an application license item keyword.  The license item value must have been numeric in the loaded application license section.  This method is intended for InterSystems internal use.  Customer code should use $SYSTEM.License.TakeApplicationLicense)().<br><br>
/// Arguments:<br>
/// <br>AppName:  The 'Company.Application' value from the section name in iris.key for protected application license sections, or the name of the unprotected application license section loaded with LoadAppLicenseFile().<br>
/// FeatureKeyword:  The application keyword being consumed.  If the FeatureKeyword is omitted, the default value is "Concurrent Users".<br>
/// LicenseId:  User identifier under which to be licensed.  Used for licensing of CSP sessions.  Non CSP server processes will use the process InterSystems IRIS license id.<br.<br>
/// <br><br>Return value:  0 - no license available, positive integer - the number of times this user has taken this license.<br>
/// An INVALID ARGUMENT error will be generated if a license has not been loaded for this application name.
ClassMethod takeAppLicense(AppName As %String, FeatureKeyword As %String, LicenseId As %String) As %Integer [ Internal ]
{
}

/// $SYSTEM.License.ReturnUserLicense(AppName,FeatureKeyword,.Released)<br>
/// Return (release) a license unit for a TrakCare license and feature.  The license feature value must be numeric in the loaded TrakCare license section.
/// Releases the license resource associated with the license user Id of the current process, or the session license Id in the case of CSP.<br><br>
/// Arguments:<br>
/// <br> AppName:  The 'Company.Application' value from the section name in iris.key for protected application license sections, or the name of the unprotected application license section loaded with LoadAppLicenseFile().<br>
/// FeatureKeyword:  The feature keyword being released.  If the FeatureKeyword is omitted, the default value is "Concurrent Users".<br>
/// Released:  Returns the new count of connections to AppName/FeatureKeyword for this user.
/// <br><br>Return value:  $$$OK, or error status.
/// <br>An error status containing an INVALID ARGUMENT error will be returned if no license has been loaded for AppName.
/// <br>The ByRef Released argument returns 1 if a license was held and released, otherwise 0. 
/// <br><br> The session object (%session) must be in scope.
/// <br><br> This API is intended for use with the old [TrakCare] license.  Other application licenses should use ReturnApplicationLicense()
ClassMethod ReturnUserLicense(AppName As %String, FeatureKeyword As %String = "Concurrent Users", ByRef Released As %Integer) As %Status [ Internal ]
{
}

/// <br> Take an application license for application = AppName, license feature = FeatureKeyword.
/// <br> The license is taken in the name of the process or CSP session's licensed user.
/// <br> AppName:  The 'Company.Application' value from the section name in iris.key for protected application license sections, or the name of the unprotected application license section loaded with LoadAppLicenseFile(), or the TrakCare application.<br>
/// <br> FeatureKeyword is the license feature taken.  The default value is "Concurrent Users". 
/// <br> Count, returns the resulting number of AppName/FeatureKeyword connections for the user.
/// <br><br> The session object (%session) must be in scope.
/// <br><br> This API is intended for use with the old [TrakCare] license.  Other application licenses should use TakeApplicationLicense()
ClassMethod TakeUserLicense(AppName As %String, FeatureKeyword As %String = "Concurrent Users", ByRef Count As %Integer) As %Status [ Internal ]
{
}

/// $SYSTEM.License.LUAvailable() returns number of license units currently available at the local InterSystems IRIS instance.
ClassMethod LUAvailable() As %Integer
{
}

/// $SYSTEM.License.LUConsumed() returns number of license units currently consumed at the local InterSystems IRIS instance.
ClassMethod LUConsumed() As %Integer
{
}

/// $SYSTEM.License.LUMinAvailable() returns the minimum number of license units available at the local InterSystems IRIS instance since it started.  This value is the low water mark of license availability on the local InterSystems IRIS instance.
ClassMethod LUMinAvailable() As %Integer
{
}

/// $SYSTEM.License.LUMaxConsumed() returns the maximum number of license units consumed at the local InterSystems IRIS instance since it started.  This value is the high water mark of license consumption on the local InterSystems IRIS instance.
ClassMethod LUMaxConsumed() As %Integer
{
}

/// $SYSTEM.License.LUMaxConsumedReset([Argument]) resets the recorded peak levels of various measures of license use by setting the internal counters to the current usage level and returns the previously recorded maximum count.  The usage counts are local to the InterSystems IRIS instance and represent maximum usage since the instance started or the counter was last reset.
/// <br>Arguments
/// <ul>
/// <li>No Argument:  Resets maximum license units consumed as returned by $SYSTEM.License.LUMaxConsumed() and the maximum connection count as returned by $SYSTEM.License.MaxConnections() to the current usage levels. The previously recorded $SYSTEM.License.LUMaxConsumed() value is returned.</li>
/// <li>Argument = "Users":  Resets maximum license units consumed as returned by $SYSTEM.License.LUMaxConsumed() to the current usage level. The previously recorded $SYSTEM.License.LUMaxConsumed() count is returned.</li>
/// <li>Argument = "Connections":   Resets maximum concurrent connections, as returned by $SYSTEM.License.InstanceConnectionsMax() to the current usage level. The previously recorded $SYSTEM.License.InstanceConnectionsMax() is returned.</li>
/// <li>Argument = "CSPUsers":   Resets maximum concurrent CSP Users, as returned by $SYSTEM.License.MaxCSPUsers() to the current usage level. The previously recorded $SYSTEM.License.MaxCSPUsers() is returned.</li>
/// <li>Argument = "Processes": Resets maximum concurrent licensed process count, as returned by $SYSTEM.License.ProcMaxConsumed() to the current usage level. The previously recorded $SYSTEM.License.ProcMacConsumed() is returned.</li>
/// <li>Argument = "CSPGrace": Resets maximum concurrent number of CSP sessions in the "grace" period, as returned by $SYSTEM.License.MaxCSPGrace() to the current usage level. The previously recorded $SYSTEM.License.MaxCSPGrace() is returned.</li>
/// <li>Argument = "*": Resets all maximum license use counts to the current usage counts. The previously recorded $SYSTEM.License.LUMaxConsumed() is returned.</li>
/// </ul>
/// 
ClassMethod LUMaxConsumedReset() As %Integer
{
}

/// Reset distributed peak levels on the License Server for this Instance and it's license key.
/// This is similar to $SYSTEM.License.LUMaxConsumedReset method, but resets the distributed values.
/// 'Counter' may be either 'Users' or 'Connections'. If 'Counter' is null, both are reset
ClassMethod DistributedMaxReset(Counter As %String = "") As %Status
{
}

/// $SYSTEM.License.ProcAvailable returns the number of additional InterSystems IRIS User process licenses available on this InterSystems IRIS instance.
/// (Applicable only for license types that restrict the number of processes, i.e. 'Real Time' licenses.)
ClassMethod ProcAvailable() As %Integer
{
}

/// $SYSTEM.License.ProcConsumed returns the number of InterSystems IRIS User process licenses currently in use on this InterSystems IRIS instance.
/// (Applicable only for license types that restrict the number of processes, i.e. 'Real Time' licenses.)
ClassMethod ProcConsumed() As %Integer
{
}

/// $System.License.InstanceConnections() - return current count of connections to instance.
ClassMethod InstanceConnections()
{
}

/// $System.License.InstanceConnectionsMax() - return maximum concurrent connections to instance since it restarted or the maximum was reset.
ClassMethod InstanceConnectionsMax()
{
}

/// $SYSTEM.License.ProcMaxConsumed returns the maximum number of InterSystems IRIS User processes running concurrently since the instance started.
ClassMethod ProcMaxConsumed() As %Integer
{
}

/// $SYSTEM.License.ProcMinAvailable returns the minimum number of additional processes available at any time since the instance started.  (Applicable only with license types that restrict the number of processes.)
ClassMethod ProcMinAvailable() As %Integer
{
}

/// $SYSTEM.License.PublicWebAppUser declares an application to be a public web application for the purpose of a Web Add-on license.
/// This system method requires that the active license key be a Real Time license or have the Web Add-on feature enabled.
/// The return value is 1 on success, 0 on failure.  Failure indicates the license key does not support this option.
/// The PublicWebAppUser system method must be called from the OnStartSession method of the Session Events class defined for the CSP application as follows:
/// <ol>
/// <p>1) Create a subclass of the %CSP.SessionEvents class and define a method to handle the OnStartSession event.  Call $system.License.PublicWebAppUser() in the OnStartSession class method.</p>
/// <p>2) Define this class as the Event Class for the CSP application. <br>
///  <br>
///    Management Portal -> System Administration -> Security -> Applications -> Web Applications <br>
///  <br>
///    Enter the %CSP.SessionEvents subclass in the " Event Class:" box. <br>
///  <br>
/// <p>3) Insure that "Unauthenticated" is checked for "Allowed Authentication Methods".</p>
/// 
/// 
/// Example:  The following code could be placed in ClassMethod OnStartSession of the class extending %CSP.SessionEvents that acts as the session event handler for the public application.
/// <example>
/// try { s x=$system.License.PublicWebAppUser() } catch { /* log error */ }
/// q $$$OK
/// </example>
/// 
ClassMethod PublicWebAppUser() As %Integer
{
}

/// $SYSTEM.License.PublicWebAppUserCount returns the current number of public web application connections active.
ClassMethod PublicWebAppUserCount() As %Integer
{
}

/// $SYSTEM.License.PublicWebAppUsersMax() returns the maximum number of public web application connections active at any one time.
ClassMethod PublicWebAppUsersMax() As %Integer
{
}

/// $SYSTEM.License.SetConnectionLimit establishes the maximum number of connections permitted per user on this instance.
/// This enables a system administrator to prevent a user from making so many connections to a InterSystems IRIS instance that they consume all available license units.
/// Calling $SYSTEM.License.SetConnectionLimit($SYSTEM.License.MaxConnections()) permits a user to make the maximum connections permitted
/// but prevent transitioning to the license unit per connection state, insuring the user will consume no more than one license unit.  A zero argument removes the limit.
/// The failure to obtain a license will be indicated in the normal way.  For example, a call to $system.License.Login() will return zero (0) while a failure to log in to a new terminal connection will receive a <LICENSE LIMIT EXCEEDED> error.
/// However, these license failures will not be reported in the console log.
/// The method returns the former maximum value.
/// <br><br>The limit applies only to the local instance.  If an InterSystems IRIS license is shared among several instances it is still possible to exceed $SYSTEM.License.MaxConnections() over all instances.  This can be avoided by setting the limit low enough on each instance that the combined connections to all instances will be unlikely to exceed $SYSTEM.License.MaxConnections().
/// <br><br>$SYSTEM.License.SetConnectionLimit reqires access to the %Admin Manage resource.  It is suggested that customers call this API from SYSTEM^%ZSTART.
/// 
ClassMethod SetConnectionLimit(MaxCon As %Integer) As %Integer
{
}

/// $SYSTEM.License.SetUserLimit establishes the maximum number of license units that this InterSystems IRIS instance will consume.
/// This permits a system manager to prevent a InterSystems IRIS instance from consuming all the license units in a key shared among multiple InterSystems IRIS instances.
/// The Method returns the former maximum value.
/// In the absence of a call to $SYSTEM.License.SetUserLimit(max) a InterSystems IRIS instance may consume
/// all available license units. <br> <br>
/// Reqires access to the %Admin Manage resource.
/// 
ClassMethod SetUserLimit(MaxLU As %Integer) As %Integer
{
}

/// $SYSTEM.License.ReadDurationValues() returns the upper limit in seconds each histogram bucket represents. The values are returned as a list with 5 elements. The sixth value is not provided because there is no upper limit. Returning time bucket values in a list permits the number of buckets and their values to be changed in the future with little impact on the code.
ClassMethod ReadDurationValues() As %List
{
}

/// $SYSTEM.License.ReadDurationCounts() returns the number of times a logout occurred within the time indicated by the corresponding ReadDurationValues. The values are returned as a list. $ListLength is currently 6.
ClassMethod ReadDurationCounts() As %List
{
}

/// $SYSTEM.License.ClearDurationCounts() sets the collection area of the LoginDuration query to all zeros and returns the counts prior to change.  Requires the %Manager role.
ClassMethod ClearDurationCounts() As %List
{
}

/// Modify how the License User Identifier is specified.
/// By default, the client IP address is used to identify a user to the InterSystems IRIS license tracking subsystem.
/// If InterSystems IRIS is installed
/// with the normal security level, each process will be have a user identity ($username).  
/// The $SYSTEM.License.UserNameLicensing system method can be called to make the InterSystems IRIS license
/// subsystem use $username as the license user identifier. 
/// The client IP address will be appended to $Username separated by an "@" sign to form the complete license identifier.<br><br>
/// $SYSTEM.License.UserNameLicensing modifies the system state.  It can be called from 
/// SYSTEM^%ZSTART to enable user name licensing at instance startup. <br> <br>
/// $SYSTEM.License.UserNameLicensing(1) enables $username based licensing and returns the previous state. <br>
/// $SYSTEM.License.UserNameLicensing(0) disables $username based licensing and returns the previous state. <br>
/// $SYSTEM.License.UserNameLicensing() returns the current state. <br> <br>
/// $SYSTEM.License.UserNameLicensing(0) returns an UNLICENSED error if called with RealTime 
/// or Web Add-On keys, because these license types require UserNameLicensing. <br><br>
/// $SYSTEM.License.UserNameLicensing(1) returns an UNLICENSED error if called with a 
/// 'Core Capacity' License Type, as this combination is invalid. <br><br>
/// 
ClassMethod UserNameLicensing(OnOffState As %Integer) As %Integer
{
}

/// Query returns data displayed by ##class(%SYSTEM.License).ShowCounts()
/// <ul>
/// <li>Instance License Use:  Text describing meaning of row data.</li>
/// <li>License Units:  Value (count) described by text.</li>
/// </ul>
/// The data source is the local InterSystems IRIS instance. 
Query Counts() As %Query(ROWSPEC = "InstanceLicenseUse:%String,License Units:%String")
{
}

ClassMethod CountsExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod CountsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = CountsExecute ]
{
}

ClassMethod CountsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = CountsFetch ]
{
}

/// Decodes the license capacity fields of the License Authorization field of the license key.
/// <ul>
/// <li>Capacity Field:  Licensed capacity name.</li>
/// <li>License Units:  Licensed capacity value.</li>
/// </ul>
/// The data source is the local InterSystems IRIS instance.
/// <br><br>
/// The 'flag' argument is for internal use only.
Query Decode(flag As %Integer = 0) As %Query(ROWSPEC = "CapacityField:%String,Value:%String")
{
}

ClassMethod DecodeExecute(ByRef qHandle As %Binary, flag As %Integer = 0) As %Status [ Internal ]
{
}

ClassMethod DecodeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = DecodeExecute ]
{
}

ClassMethod DecodeClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = DecodeFetch ]
{
}

/// This query returns the fields of the active license key.
/// <br>
/// <ul>
/// <li>Field:  Text to the left of the '=' sign in the [License] section of the license key file.</li>
/// <li>Value:  Value to the right of the '=' sign.</li>
/// </ul>
/// The value of the Sections argument filters what is returned.<br>
/// <ul>
/// <li> 1  Return main license section [License].
/// <li> 2  Return application license sections.
/// <li> 3  Return all license sections.
/// </ul>
/// The name of each application license section enclosed in square brackets will begin each section in the "Field" field with the "Value" field empty.
/// <br><br>The data source is the local InterSystems IRIS instance.
Query Key(Sections As %Integer) As %Query(ROWSPEC = "Field:%String,Value:%String")
{
}

ClassMethod KeyExecute(ByRef qHandle As %Binary, Sections As %Integer = 3) As %Status [ Internal ]
{
}

ClassMethod KeyFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = KeyExecute ]
{
}

ClassMethod KeyClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = KeyFetch ]
{
}

/// Returns the IP address and port of the active License Server.
/// This information is not applicable for Single Server keys.<br><br>
/// Note:  Not applicable with a Single-Server key.<br>
/// The data source is the local InterSystems IRIS instance.
Query LicenseManager() As %Query(ROWSPEC = "AddressPort:%String,Value:%String")
{
}

ClassMethod LicenseManagerExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod LicenseManagerFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = LicenseManagerExecute ]
{
}

ClassMethod LicenseManagerClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = LicenseManagerFetch ]
{
}

/// This query returns license usage for this InterSystems IRIS instance by Process.<br><br>
/// The PID is the operating system Process Identifier.<br><br>
/// The DisplayPID is display form for PID, it is hexadecimal value in VMS.<br><br>
/// The Process field is one of the following process login types:<br>
/// <ul>
/// <li>System	- system processes that do not consume a license unit.</li>
/// <li>User	- Regular user (terminal, ODBC, Cache Direct) login.</li>
/// <li>CSP		- Cache Server Pages server process.  A CSP server process does not maintain an association with an internal license table entry.  The association is rather with the session.  For this reason, information regarding number of connections, and license units is not available for CSP processes.  Use the UserList query to obtain this information for CSP sessions.</li>
/// <li>Diagnostic - Process is logged in to InterSystems IRIS with the "-B" command line argument and is using the diagnostic license unit.</li>
/// <li>Server	- A server process (eg the COMMCTRL process) which does not consume a license unit, but which creates jobs which do consume license units.</li>
/// <li>Pending	- A process for which license acquisition is pending.  Can occur when deferred license acquisition is in effect.</li>
/// </ul>
/// The LID field contains the License Login UserId for this process.<br><br>
/// The Type field contains the License login type and is one of the following:<br>
/// <ul>
/// <li>User 	- Regular user login </li>
/// <li>CSP		- Cache Server Page login </li>
/// <li>Mixed	- Regular user plus Cache Server Page login </li>
/// <li>Grace	- Logged out CSP session waiting for grace period to expire.</li>
/// </ul>
/// Con is the number of connections to this InterSystems IRIS instance by the user represented by LID.<br><br>
/// MaxCon is the maximum number of concurrent connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// CSPCon is the number of CSP sessions open to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// LU is the number of License Units consumed on this InterSystems IRIS instance by the user represented by the UserId.<br><br>
/// Active is the time in seconds the UserId has been logged in to this InterSystems IRIS instance.<br><br>
/// Grace is the amount of time this license unit will remain in the grace period if all connections were closed immediately.<br><br>
/// The data source is the local InterSystems IRIS instance.
Query ProcessList(Filter As %String = "") As %Query(ROWSPEC = "PID:%Integer,DisplayPID:%String,Process:%String,LID:%String:UserId,Type:%String,Con:%Integer,MaxCon:%Integer,CSPCon:%Integer,LU:%Integer,Active:%Integer,Grace:%Integer")
{
}

ClassMethod ProcessListExecute(ByRef qHandle As %Binary, Filter As %String = "") As %Status [ Internal ]
{
}

ClassMethod ProcessListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ProcessListExecute ]
{
}

ClassMethod ProcessListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ProcessListFetch ]
{
}

/// Query returns license usage summary as displayed by $System.License.ShowSummary
/// <br><br>This represents the view of distributed and local license use maintained by the license server.
/// Local and distributed Authorized, Current, and Maximum license unit usage levels are returned.
/// Current and Maximum connections to the local InterSystems IRIS instance are returned.<br><br>
/// Note:  Not applicable with a Single-Server key.<br><br>
/// The data source is both the local InterSystems IRIS instance and the license server.
/// <br><br>Example:<example>
/// ;1) run query %SYSTEM.License.Summary and place results in:
/// ;   headings(c) = heading_text for column c
/// ;   data(r,c) = data for row r, column c
/// ;2) write the results to the current output device.
/// 
/// s Rset=##class(%ResultSet).%New("%SYSTEM.License.Summary")
/// if 'Rset s status="Could not form query %SYSTEM.License.Summary." w !,status q
/// s r=Rset.Execute()
/// if r {
///  s ncol=Rset.GetColumnCount()
///  f i=1:1:ncol s headings(i)=Rset.GetColumnName(i)
///  s nrec=0
///  While (Rset.Next()) {
///   s nrec=nrec+1
///   s ncol=Rset.GetColumnCount()
///   f i=1:1:ncol s data(nrec,i)=Rset.GetData(i)
///  }
///  d Rset.Close()
///  s status=nrec_" entries added to array"
/// }
/// i 'r s status="Could not execute query %SYSTEM.License.Summary." w !,status q
/// w !!,headings(1),?40,headings(2),?60,headings(3),!
/// for i=1:1:nrec w !,data(i,1),?40,data(i,2),?60,data(i,3)
/// q
/// </example>
/// 
Query Summary() As %Query(ROWSPEC = "LicenseUnitUse:%String,Local:%String,Distributed:%String")
{
}

/// This method's sole purpose is to call $SYSTEM.License.InstanceConnections() and $SYSTEM.License.InstanceConnectionsMax() without getting an unimplemented error until everyone upgrades their kernel.
ClassMethod SummaryExecuteGetCon() As %String [ Internal ]
{
}

ClassMethod SummaryExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod SummaryFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = SummaryExecute ]
{
}

ClassMethod SummaryClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = SummaryFetch ]
{
}

/// This query returns license use by User Id
/// <br><br>
/// The UserId field contains the License Login UserId.
/// The Type field contains the login type and is one of the following:<br><br>
/// <ul>
/// <li>User 	- Regular user login </li>
/// <li>CSP		- Cache Server Page login </li>
/// <li>Mixed	- Regular user plus Cache Server Page login </li>
/// <li>Grace	- Logged out CSP session waiting for grace period to expire.</li> 	
/// </ul>
/// Connects is the number of connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// MaxCon is the maximum number of concurrent connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// CSPCon is the number of CSP sessions open to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// LU is the number of License Units consumed on this InterSystems IRIS instance by the user represented by the UserId.<br><br>
/// Active is the time in seconds the UserId has been logged in to this InterSystems IRIS instance.<br><br>
/// Grace is the amount of time this license unit will remain in the grace period if all connections were closed immediately.<br><br>
/// The data source is the local InterSystems IRIS instance.
Query UserList(Filter As %String = "") As %Query(ROWSPEC = "UserId:%String,Type:%String,Connects:%Integer,MaxCon:%Integer,CSPCon:%Integer,LU:%Integer,Active:%Integer,Grace:%Integer")
{
}

ClassMethod UserListExecute(ByRef qHandle As %Binary, All As %Integer = 0, Filter As %String = "") As %Status [ Internal ]
{
}

ClassMethod UserListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = UserListExecute ]
{
}

ClassMethod UserListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = UserListFetch ]
{
}

/// This query is similar to the UserList query, but it returns the TrakCare license usage in an additional column as a list.
/// 
/// <br><br>
/// The UserId field contains the License Login UserId.
/// The Type field contains the login type and is one of the following:<br><br>
/// <ul>
/// <li>User 	- Regular user login </li>
/// <li>CSP		- Cache Server Page login </li>
/// <li>Mixed	- Regular user plus Cache Server Page login </li>
/// <li>Grace	- Logged out CSP session waiting for grace period to expire.</li> 	
/// </ul>
/// Connects is the number of connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// MaxCon is the maximum number of concurrent connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// CSPCon is the number of CSP sessions open to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// LU is the number of License Units consumed on this InterSystems IRIS instance by the user represented by the UserId.<br><br>
/// Active is the time in seconds the UserId has been logged in to this InterSystems IRIS instance.<br><br>
/// Grace is the amount of time this license unit will remain in the grace period if all connections were closed immediately.<br><br>
/// TrakLicenses is a list of TrakCare license features held by the UserId.
/// The data source is the local InterSystems IRIS instance.
Query TrakCareUserList() As %Query(ROWSPEC = "UserId:%String,Type:%String,Connects:%Integer,MaxCon:%Integer,CSPCon:%Integer,LU:%Integer,Active:%Integer,Grace:%Integer,TrakLicenses:%List") [ Internal ]
{
}

ClassMethod TrakCareUserListExecute(ByRef qHandle As %Binary, All As %Integer = 0) As %Status [ Internal ]
{
}

ClassMethod TrakCareUserListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = UserListExecute ]
{
}

ClassMethod TrakCareUserListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = UserListFetch ]
{
}

/// This query is similar to the UserList query, but it returns the Application license usage in an additional column as a list.
/// <br> It accepts two parameters:
/// <br> AppName:  The 'Company.Application' value from the section name in iris.key for protected application license sections, or the name of the unprotected application license section loaded with LoadAppLicenseFile().
/// <br> ShowCounts:  If 1, the taken keywords will be returned as KeywordName=TimesTaken in the AppLicenses field.  If zero, only the KeywordName will be returned for taken keywords.
/// <br>
/// The UserId field contains the License Login UserId.
/// The Type field contains the login type and is one of the following:<br><br>
/// <ul>
/// <li>User 	- Regular user login </li>
/// <li>CSP		- Cache Server Page login </li>
/// <li>Mixed	- Regular user plus Cache Server Page login </li>
/// <li>Grace	- Logged out CSP session waiting for grace period to expire.</li> 	
/// </ul>
/// Connects is the number of connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// MaxCon is the maximum number of concurrent connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// CSPCon is the number of CSP sessions open to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// LU is the number of License Units consumed on this InterSystems IRIS instance by the user represented by the UserId.<br><br>
/// Active is the time in seconds the UserId has been logged in to this InterSystems IRIS instance.<br><br>
/// Grace is the amount of time this license unit will remain in the grace period if all connections were closed immediately.<br><br>
/// AppLicenses is a list of Application license features held by the UserId.
/// The data source is the local InterSystems IRIS instance.
Query ApplicationUserList(AppName As %String, ShowCounts As %Integer) As %Query(ROWSPEC = "UserId:%String,Type:%String,Connects:%Integer,MaxCon:%Integer,CSPCon:%Integer,LU:%Integer,Active:%Integer,Grace:%Integer,AppLicenses:%List")
{
}

ClassMethod ApplicationUserListExecute(ByRef qHandle As %Binary, AppName As %String = "ISC.TrakCare", ShowCounts As %Integer = 0) As %Status [ Internal ]
{
}

ClassMethod ApplicationUserListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = UserListExecute ]
{
}

ClassMethod ApplicationUserListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = UserListFetch ]
{
}

/// This query returns all license slots by User Id, or free. 
/// <br><br>
/// The UserId field contains the License Login UserId.
/// The Type field contains the login type and is one of the following:<br><br>
/// <ul>
/// <li>User 	- Regular user login </li>
/// <li>CSP		- Cache Server Page login </li>
/// <li>Mixed	- Regular user plus Cache Server Page login </li>
/// <li>Grace	- Logged out CSP session waiting for grace period to expire.</li>
/// </ul>
/// Connects is the number of connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// MaxCon is the maximum number of concurrent connections to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// CSPCon is the number of CSP sessions open to this InterSystems IRIS instance by the user represented by UserId.<br><br>
/// LU is the number of License Units consumed on this InterSystems IRIS instance by the user represented by the UserId.<br><br>
/// Active is the time in seconds the UserId has been logged in to this InterSystems IRIS instance.<br><br>
/// Grace is the amount of time this license unit will remain in the grace period if all connections were closed immediately.<br><br>
/// 
/// The data source is the local InterSystems IRIS instance.
Query UserListAll() As %Query(ROWSPEC = "UserId:%String,Type:%String,Connects:%Integer,MaxCon:%Integer,CSPCon:%Integer,LU:%Integer,Active:%Integer,Grace:%Integer")
{
}

ClassMethod UserListAllExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod UserListAllFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = UserListExecute ]
{
}

ClassMethod UserListAllClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = UserListFetch ]
{
}

/// Generic license server query methods.  These implement all the license server queries.
/// <br><br>
/// InitQuery2LS:  Sends a query request to the license server and returns the open device name, expected record count, and size of record length header.
/// Input values:<br>
///     QueryType = query to initialize<br>
/// Return values:<br>
///     Device = TCP binding device name.  eg. |TCP|3456<br>
/// 		RecordCount = number of records that will be returned.<br>
/// 		LenLen = Size in characters of the length header of returned records.<br>
/// 
ClassMethod InitQuery2LS(QueryType As %Integer, ByRef Device As %String, ByRef RecordCount As %Integer, ByRef LenLen As %Integer) As %Status [ Internal ]
{
}

/// Expand appnum,kwnum;...;appnum,kwnum to AppName,KWname;...;AppName,KWname for ConnectionList with applications query to license server.
ClassMethod ExpandAppUsage(in As %String) As %String [ Internal, Private ]
{
}

/// ExecuteQuery2LS<br>
/// Execute a QueryType query to the license server.<br>
/// <br><br>
/// qHandle (output) = returned query handle
/// QueryType (input) = query type, values are:<br>
/// 		9 = ActiveServerList<br>
/// 		10 = KeyList<br>
///     11 = ConnectionList<br>
///     12 = AllKeyConnectionList<br>
/// 
/// 	Invariants:  On return the current I/O device is restored and TCP device is closed.
/// 
ClassMethod ExecuteQuery2LS(ByRef qHandle As %Binary, QueryType As %Integer = 0) As %Status [ Internal ]
{
}

/// The ActiveServerList query returns all Active InterSystems IRIS instances served by the license server.
/// <br><br>
/// The Address field contains the IP address of the host where the instance is running.<br>
/// The Instance field contains the instance name.<br>
/// The OrderNumber field contains the OrderNumber field of the License key the Instance is using.<br><br>
/// The data source is the license server, and this query will open a TCP port to receive data from the license server.
Query ActiveServerList() As %Query(ROWSPEC = "Address:%String,InstanceName:%String,OrderNumber:%String")
{
}

ClassMethod ActiveServerListExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod ActiveServerListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ActiveServerListExecute ]
{
}

ClassMethod ActiveServerListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ActiveServerListFetch ]
{
}

/// The LicenseServerKeyList query returns all license keys maintained by the license server.
/// <br>
/// <ul>
/// <li>The LicenseCapacity field is the data to the right of "LicenseCapacity=" in the key file.</li>
/// <li>The CustomerName field is the data to the right of "CustomerName=" in the key file.</li>
/// <li>The OrderNumber field is the data to the right of "OrderNumber=" in the key file.</li>
/// <li>The ExpirationDate field is the data to the right of "ExpirationDate" in the key file.</li> 
/// <li>The AuthorizationKey field is the data to the right of "AuthorizationKey" in the key file.</li> 
/// <li>The MachineID field is the data to the right of "MachineID=" in the key file.</li>
/// <li>The LicenseID field is the data to the right of "LicenseID=" in the key file.</li>
/// </ul>
/// The data source is the license server, and this query will open a TCP port to receive data from the license server.
Query LicenseServerKeyList() As %Query(ROWSPEC = "LicenseCapacity:%String,CustomerName:%String,OrderNumber:%String,ExpirationDate:%String,AuthorizationKey:%String,MachineId:%String,LicenseID:%String")
{
}

ClassMethod LicenseServerKeyListExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod LicenseServerKeyListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = LicenseServerKeyListExecute ]
{
}

ClassMethod LicenseServerKeyListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = LicenseServerKeyListFetch ]
{
}

/// The ConnectionList query returns a list of active connections consuming license units from the current key.
/// <br>
/// <ul>
/// <li>The UserId field contains the License User Id of the entity consuming one or more license units.</li>
/// <li>The LicenseUnits field contains the number of license units consumed.  This can be a number, or the string "shr", indicating that the connection shares a license unit with another connection by the same License UserId.</li>
/// <li>The Connections field contains the number of connections the UserId entity has made to the the InterSystems IRIS server.</li>
/// <li>The ServerIP field contains the address of the the InterSystems IRIS server to which the connection was made.</li>
/// <li>The Instance field contains the name of the InterSystems IRIS instance to which the connection was made.</li>
/// </ul>
/// The data source is the license server, and this query will open a TCP port to receive data from the license server.
Query ConnectionList() As %Query(ROWSPEC = "UserId:%String,LicenseUnits:%String,Connections:%String,ServerIP:%String,Instance:%String")
{
}

ClassMethod ConnectionListExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod ConnectionListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ConnectionListExecute ]
{
}

ClassMethod ConnectionListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ConnectionListFetch ]
{
}

/// Get all Application,KeyWord pairs taken for UserId.
/// Used by ConnectionAppList query when license is single server, hence no license server.
ClassMethod AppsTakenByUser(UserId As %String) As %String [ Internal, Private ]
{
}

/// The ConnectionAppList query returns a list of active connections consuming license units from the current key.
/// It is identical to the ConnectionList query, with an additional field which contains applications that have been taken by the UserId on the ServerIP.
/// <br>
/// <ul>
/// <li>The UserId field contains the License User Id of the entity consuming one or more license units.</li>
/// <li>The LicenseUnits field contains the number of license units consumed.  This can be a number, or the string "shr", indicating that the connection shares a license unit with another connection by the same License UserId.</li>
/// <li>The Connections field contains the number of connections the UserId entity has made to the the InterSystems IRIS server.</li>
/// <li>The ServerIP field contains the address of the the InterSystems IRIS server to which the connection was made.</li>
/// <li>The Instance field contains the name of the InterSystems IRIS instance to which the connection was made.</li>
/// <li>The ApplicationUse field contains the applications taken by the connection formatted as AppName,Feature;AppName,Feature;...;AppName,Feature.</li>
/// </ul>
/// The data source is the license server, and this query will open a TCP port to receive data from the license server.
/// The license server maintains counts of ISC.Appname license sections but does not manage other application license sections.  Usage of other license sections can be examined with the ApplicationUserList query which returns license use for all applications on the current InterSystems IRIS instance.
Query ConnectionAppList() As %Query(ROWSPEC = "UserId:%String,LicenseUnits:%String,Connections:%String,ServerIP:%String,Instance:%String,ApplicationUse:%String")
{
}

ClassMethod ConnectionAppListExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod ConnectionAppListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ConnectionListExecute ]
{
}

ClassMethod ConnectionAppListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ConnectionListFetch ]
{
}

/// The AllKeyConnectionList query returns a list of active connections consuming license units from all keys maintained by the license server.
/// <br><br>
/// The UserId field contains the License User Id of the entity consuming one or more license units.<br>
/// The LicenseUnits field contains the number of license units consumed.  This can be a number, or the string "shr", indicating that the connection shares a license unit with another connection by the same License UserId.<br>
/// The Connections field contains the number of connections the UserId entity has made to the the InterSystems IRIS server.<br>
/// The ServerIP field contains the address of the the InterSystems IRIS server to which the connection was made.<br>
/// The Instance field contains the name of the InterSystems IRIS instance to which the connection was made.<br><br>
/// The data source is the license server, and this query will open a TCP port to receive data from the license server.
Query AllKeyConnectionList() As %Query(ROWSPEC = "UserId:%String,LicenseUnits:%String,Connections:%String,ServerIP:%String,Instance:%String,OrderNumber:%String")
{
}

ClassMethod AllKeyConnectionListExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod AllKeyConnectionListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = AllKeyConnectionListExecute ]
{
}

ClassMethod AllKeyConnectionListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = AllKeyConnectionListFetch ]
{
}

/// 
/// The LoginDuration query returns a histogram of the durations license unit consumption on the local instance.
/// <br><br>
/// The Duration field contains a duration of license unit consumption in seconds.  The duration field is text suitable for display, not a number.  The final row will be prefixed with a ">" sign to indicate that the duration of the row has no upper limit<br>
/// The Count field contains the number of times a license unit was consumed for less than the corresponding Duration field.
/// The Count field is not cumulative.<br><br>
/// The data source is the local InterSystems IRIS instance.
/// <br><br>Example:<example>
/// ;1) run query %SYSTEM.License.LoginDuration
/// ;2) write the results to the current output device.
/// Set rset=##class(%Library.ResultSet).%New("%SYSTEM.License:LoginDuration")
/// If rset="" Write !,"Create Query failed" d DisplayError^%apiOBJ(%objlasterror) Quit
/// Set status=rset.Execute()
/// If $$$ISERR(status) Write !,"Execute Query failed:" Do DisplayError^%apiOBJ(status) Quit
/// Set colcnt=rset.GetColumnCount()
/// For i=1:1:colcnt Set colname(i)=rset.GetColumnName(i)
/// Write !! For i=1:1:colcnt Write $j(colname(i),15)," "
/// while rset.Next() {
///    Write ! For i=1:1:colcnt Write $j(rset.GetData(i),15)," "
/// }
/// ;Results look like this:
/// ;
/// ;Testing %SYSTEM.License.LoginDuration query.
/// ;      Duration           Count
/// ;             1               0
/// ;            15            7548
/// ;            60            7261
/// ;           900             260
/// ;          3600               0
/// ;        > 3600               0
/// </example>
Query LoginDuration() As %Query(ROWSPEC = "Duration:%String,Count:%String")
{
}

ClassMethod LoginDurationExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
}

ClassMethod LoginDurationFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = LoginDurationExecute ]
{
}

ClassMethod LoginDurationClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = LoginDurationFetch ]
{
}

}
