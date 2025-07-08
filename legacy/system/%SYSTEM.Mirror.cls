/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class contains public mirroring methods which are accessable
/// from any namespace. These methods can be invoked
/// either via ##class(%SYSTEM.Mirror).(&LT methodname &GT) or via 
/// $SYSTEM.Mirror.(&lt methodname &gt). Most of the public API for 
/// mirroring is in the <class>SYS.Mirror</class> class however that
/// class is only accessable to programs running in %SYS.
Class %SYSTEM.Mirror Extends Help [ Abstract, System = 4 ]
{

/// <p>
/// Test whether this system is configured to join a mirror.
/// <br><br>
/// This method is useful when a site has code that should only be
/// run on the Primary node when the node is a mirror member. This
/// could be used in ^ZSTART or ^ZSTU to skip this code during startup
/// when the node is a mirror member (startup code for mirrors 
/// should go in NotifyBecomePrimary^ZMIRROR).
/// <br><br>
/// This is also useful in conjunction with 
/// <method>$SYSTEM.Mirror.IsPrimary</method> in other code, such as
/// code that is run periodically via the TaskManager, to skip
/// running the code on non-primary mirror members as in
/// <br>
/// &nbsp&nbsp&nbsp&nbsp&nbsp quit:($SYSTEM.Mirror.IsMember() & '$SYSTEM.Mirror.IsPrimary())
/// 
/// </p>
/// <p>
/// Return Value: 
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// 0 - Node is not configured to join a mirror
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// 1 - Node is configured as a failover mirror member
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// 2 - Node is configured as an async mirror member
ClassMethod IsMember() As %Integer
{
	quit $SYSTEM.Mirror.IsMember()
}

/// <p>
/// Test whether this system is the primary mirror member.
/// </p>
/// <p>
/// Return Value: 
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// 1 = node is the primary
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// 0 = node is not the primary
ClassMethod IsPrimary() As %Boolean
{
	quit $SYSTEM.Mirror.IsPrimary()
}

/// <p>
/// Test whether this system is a backup mirror member.
/// <br><br>
/// A failover mirror member might report false for both IsPrimary and IsBackup
/// if it is in the process of connecting or has failed to connect for some
/// reason. IsBackup() is only true while the mirror data channel exists. 
/// </p>
/// <p>
/// Return Value: 
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// TRUE = node is currently connected to a mirror as a backup
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// FALSE = node is not currently connected to a mirror as a backup
ClassMethod IsBackup() As %Boolean
{
	quit $SYSTEM.Mirror.IsBackup()
}

/// <p>
/// Test whether this system is connected to a primary as an async mirror member.
/// <br><br>
/// This reports true when this node has a data channel established to a primary
/// mirror member as an async member. The node can be configured as an async member 
/// but this will report false if it does not have any data channels established at the time.
/// </p>
/// <p>
/// Return Value: 
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// TRUE = node is currently connected to a mirror as an async member
/// <br>&nbsp&nbsp&nbsp&nbsp&nbsp
/// FALSE = node is not currently connected to a mirror as an async member
ClassMethod IsAsyncMember() As %Boolean
{
	quit $SYSTEM.Mirror.IsAsyncMember()
}

/// <p>
/// Returns the name of the mirror if the instance is configured
/// as a failover mirror member or NULL if it is not.
/// </p>
ClassMethod MirrorName() As %String
{
	// If this node is not configured as a failover mirror
	// member, then return ""
	if $SYSTEM.Mirror.IsMember()'=1 {
		quit ""
	}
	s str=$SYSTEM.Mirror.GetInfo(3)  ;name,guid
	s name=$P(str,",",1)
	quit name
}

/// <p>
/// Returns the names of the mirrors the instance is a member of in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> format, 
/// or NULL if the instance is not a mirror member.
/// </p>
ClassMethod GetMirrorNames() As %String
{
	quit $SYSTEM.Mirror.GetMirrorNames()
}

/// <p>
/// GetStatus([MirrorName]) returns the current status of this mirror member.
/// <br><br>On failover members, and non-failover members which track only a single
/// mirror, the MirrorName is optional. On instances which track more than one mirror,
/// omitting the MirrorName (or passing "") returns summary information regarding the connection
/// status. Specifying the MirrorName returns the detailed
/// information below regarding that mirror.
/// <method>GetMemberStatus</method> returns the same information in a for more
/// suitable for displaying to a user. The form returned here may be more suitiable
/// for testing against in a program.
/// </p>
/// Return Value:
/// <ul>
/// <li><b>NOTINIT</b> - This instance is not yet initialized or not a member
///                      of the specified mirror.</li>
/// <li><b>PRIMARY</b> - This instance is the primary mirror member. Like <method>IsMember</method>
///                      this indicates that the node is active as the primary.
/// <li><b>BACKUP</b> - This instance is connected to the primary as a backup member.
/// <li><b>CONNECTED</b> - This instance is an async member currently connected to its server.
/// <li><b>TRANSITION</b> - In a transitional state that will soon change when initialization or 
///                         another operation completes.  This status prompts processes querying a 
///                         member's status to query again shortly.  Failover members remain in this
///                         state while retrieving and applying journals when no other failover
///                         member is primary.  This is an indication that it may become primary upon
///                         finishing, so a caller that is waiting for this member to become primary
///                         may wish to continue waiting; if there is another failover member that is
///                         primary, the state will be <b>SYNCHRONIZING</b> instead. An instance may also 
///                         enter the transition while stopping or restarting mirroring.
/// <li><b>SYNCHRONIZING</b> - Starting up or reconnecting after being stopped or disconnected, retrieving and applying journal files
///                     in order to synchronize the database and journal state before becoming Backup or Connected.
/// <li><b>WAITING</b> - For a failover member this means the member is unable to become
///                      the primary or backup for some reason. For an async
///                      member this has similar meaning, either there is some trouble preparing
///                      to contact the mirror or it failed to establish a connection to the mirror.
///                      In all cases a there should be a note in the console log as to the problem and
///                      the member should be retrying to detect when the trouble condition is resolved.</li>
/// <li><b>STOPPED</b> - Mirroring is configured but not running and will not start automatically.
///                      Either the mirror management interface has been used to stop mirroring or the current state of
///                      the system has prevented mirroring from starting (examples include emergency startup mode,
///                      insufficient license, mirror service disabled, certain errors during mirroring initialization).</li>
/// <li><b>CRASHED</b> - The mirror master job for this mirror is no longer running. Restarting InterSystems IRIS is required for mirroring to work again.
/// <li><b>MULTIASYNC^&ltm&gt/&ltn&gt</b> - Returned for async members which connect to more than
///                    one mirror when the MirrorName argument is omitted. &ltm&gt is the number of mirrors the instance is currently
///                    connected to, &ltn&gt is the number of mirrors the instance is configured
///                    to connect to. </li>
/// </ul>
ClassMethod GetStatus(MirrorName As %String = "") As %String
{
	quit $SYSTEM.Mirror.GetStatus(MirrorName)
}

/// GetMemberStatus(MirrorName) returns the current status of this mirror member based
/// on the result from <method>GetStatus</method>. The values returned here are more
/// suitable for displaying to a user.
/// <br><br>On failover members, and non-failover members which track only a single
/// mirror, the MirrorName is optional. On instances which track more than one mirror,
/// omitting the MirrorName (or passing "") returns summary information regarding the connection
/// status (eg. m/n connected). Specifying the MirrorName returns the detailed
/// information below regarding that mirror.
/// <br><br>Return values are in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> format. The 1st item in the list is
///  the current status of the member. In the future some status values may have
/// additional pieces which carry more information.<br>
/// <br><Br>The values for $LG(status,1) are:
/// <ul>
/// <li><b>Not Initialized</b> - This instance is not yet initialized, or not a member
///                      of the specified mirror.</li>
/// <li><b>Primary</b> - This instance is the primary mirror member. Like <method>IsPrimary</method>
///                      this indicates that the node is active as the primary. $LG(status,2) contains 'Trouble' when the primary is in trouble state.
/// <li><b>Backup</b> - This instance is connected to the primary as a backup member.
/// <li><b>Connected</b> - This instance is an async member currently connected to the mirror.
/// <li><b>m/n Connected</b> - Returned for async members which connect to more than
///                    one mirror when the MirrorName argument is omitted. &ltm&gt is the number of mirrors the instance is currently
///                    connected to, &ltn&gt is the number of mirrors the instance is configured
///                    to connect to. </li>
/// <li><b>Transition</b> - In a transitional state that will soon change when initialization or 
///                         another operation completes.  This status prompts processes querying a 
///                         member's status to query again shortly.  Failover members remain in this
///                         state while retrieving and applying journals when no other failover
///                         member is primary.  This is an indication that it may become primary upon
///                         finishing, so a caller that is waiting for this member to become primary
///                         may wish to continue waiting; if there is another failover member that is
///                         primary, the state will be <b>Synchronizing</b> instead.	
/// <li><b>Synchronizing</b> - Starting up or reconnecting after being stopped or disconnected, retrieving and applying journal files
///                            in order to synchronize the database and journal state before becoming Backup or Connected.
/// <li><b>Waiting</b> - For a failover member this means the member is unable to become
///                      the primary or backup for some reason. For an async
///                      member this has similar meaning, either there is some trouble preparing
///                      to contact the mirror or it failed to establish a connection to the mirror.
///                      In all cases a there should be a note in the console log as to the problem and
///                      the member should be retrying to detect when the trouble condition is resolved.</li>
/// <li><b>Stopped</b> - Mirroring is configured but not running and will not start automatically.
///                      Either the mirror management interface has been used to stop mirroring or the current state of
///                      the system has prevented mirroring from starting (examples include emergency startup mode,
///                      insufficient license, mirror service disabled, certain errors during mirroring initialization).</li>
/// <li><b>Crashed</b> - The mirror master job for this mirror is no longer running. Restarting InterSystems IRIS is required for mirroring to work again.
/// <li><b>Error</b> - An unexpected error occured. Either an error was caught or the system is
///                    in some unexpected state. $LG(status,2) contains the value of the $ZERROR variable</li>
/// <li><b>Down</b> - This member is down. This is displayed by other members when this member is down.
/// </ul>
ClassMethod GetMemberStatus(MirrorName As %String = "") As %List
{
	try { 
		#;SML2148+ ; put the second position of the returned list to be troubleflag of the primary.
		s status=$SYSTEM.Mirror.GetStatus(MirrorName)
		if (status="PRIMARY"),$p($SYSTEM.Mirror.GetInfo(2),",",12) {
			s res=$LB(..MemberStatusLogicalToDisplay(status),"Trouble")
		} else {
			s res=$LB(..MemberStatusLogicalToDisplay(status))
		}
		#;SML2148-
	} catch {
		s res=$LB("Error",$ZE)
	}
	quit res
}

/// Used to convert the string returned from $SYSTEM.Mirror.GetStatus()
/// into something more suitable for displaying to the user. The raw
/// string returned from GetMemberStatus is also returned from GetNodeInfo^MIRRORCTL
/// so we need a common subroutine to translate the results.
ClassMethod MemberStatusLogicalToDisplay(status As %String) As %String [ Internal ]
{
	if $P(status,"^")="MULTIASYNC" {  ; "MULTIASYNC^m/n" summary report 
		s connections=$P(status,"^",2)
		s status=connections_" Connected"
	} else {
		s status=$CASE(status,"NOTINIT":"Not initialized",
					   "PRIMARY":"Primary",
					   "BACKUP":"Backup",
					   "CONNECTED":"Connected",
					   "TRANSITION":"Transition",
					   "WAITING":"Waiting",
					   "STOPPED":"Stopped",
					   "SYNCHRONIZING":"Synchronizing",
					   "CRASHED":"Crashed",
					   :status)
	}
	quit status
}

/// GetMemberType() returns the mirror member type of this instance
/// <br><Br>The values returned are:
/// <ul>
/// <li><b>Indeterminate</b> - Startup is running and the configuration is not loaded yet</li>
/// <li><b>Not Member</b> - This instance is not configured to join a mirror</li>
/// <li><b>Failover</b> - This instance is configured as a failover member</li>
/// <li><b>Async</b> - This instance is configured as an async member but we cannot
///                   determine what kind of an async member it is. This occurs when a member
///                   reports its member type to another member or when the configuration cannot
///                   be read.
/// <li><b>Disaster Recovery</b> - This instance is configured as a async member for disaster recovery 
///                 purposes.</li>
/// <li><b>Read-Only Reporting</b> - This instance is configured as an async reporting node and the
///                       default for the local copy of the mirrored databases is that they 
///                       are read-only.</li>
/// <li><b>Read-Write Reporting</b> - This instance is configured as an async reporting node and the
///                       default for the local copy of the mirrored databases is that they 
///                       are writable.</li>
/// </ul>
ClassMethod GetMemberType() As %String
{
	s info=$SYSTEM.Mirror.GetInfo(4)  ;Async, Failover, Not Member or Indeterminate
	if info="Async" {
		/* For Async members we want to return additional information as
		   to their type */
		#;SML1659+
		s type=$SYSTEM.Mirror.AsyncMemberType()
		s info=$case(type,
					 0:"Disaster Recovery",
					 1:"Read-Only Reporting",
					 2:"Read-Write Reporting",
					 :"Async")
		#;SML1659-
	}
	quit info
}

/// Used to detect whether the default database for globals associated with a given
/// namepspace is mirrored. If namespace is the null string or omitted, information 
/// about the current namespace is returned.
/// <br><br>
/// Returns:
/// <ul>
/// <li>
///    non-zero - When the default database for globals is mirrored, this is -1 if it is
///        a remote database or the sfn if it is a local database. The
///        sfn is an internal value which identifies a given database and can be passed to
///        other functions to retrieve information about that database. SFN assignments can
///        change across InterSystems IRIS restarts.  A non-zero value is returned even if mirroring is
///        currently stopped.
/// </li><li>
///    zero - The default database for global is not mirrored or there was some trouble
///            executing the operation such as the namespace or the database does not exist.
/// </li>
/// </ul>
ClassMethod IsNamespaceMirrored(Namespace As %String) As %Integer [ Internal ]
{
	quit $SYSTEM.Mirror.IsNamespaceMirrored($G(Namespace))
}

}
