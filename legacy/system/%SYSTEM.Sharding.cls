/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %BigData.ShardingManager

/// This class provides an API for "manually" configuring sharding, at the level of individual 
/// InterSystems IRIS Data Platform instances.
/// <p>It can be used via the special $SYSTEM object, for example:
/// <p><dd>set status = $SYSTEM.Sharding.EnableSharding()</dd>
/// <p>The $SYSTEM.Sharding API provides an alternative to using ICM (InterSystems Cloud Manager) to provision and
/// configure sharded clusters, for scenarios ICM does not support, or situations where step-by-step
/// manual control, or avoiding the use of containers, is preferred.  Unlike ICM, which manages the
/// entire process of installing and configuring InterSystems IRIS instances to function together as sharded
/// clusters, the $SYSTEM.Sharding API adds only sharding-specific functionality, depending on
/// other InterSystems IRIS tools and APIs for tasks such as installing InterSystems IRIS instances, 
/// configuring mirroring, or creating namespaces and databases.
/// <p>Most of the $SYSTEM.Sharding API calls operate at the level of a specified master namespace.
/// The two exceptions are <method>EnableSharding</method> and <method>SetNodeIPAddress</method>, which operate on an entire InterSystems IRIS instance
/// (which may contain multiple master namespaces).
/// <p><b>Terminology</b>
/// <dl>
/// <dt><i>Sharding</i>
/// <dd>Transparent horizontal partitioning of tables across a set of <i>shards</i>.  Each <i>shard</i>
/// can be hosted on a separate InterSystems IRIS instance, on a separate machine, providing horizontal 
/// performance scaling for queries and data ingestion. Horizontal partitioning means partitioning 
/// by rows, as opposed to vertical partitioning by columns. Each partition of a horizontally 
/// partitioned table contains a subset of the table's rows, and each row is contained in exactly one
/// partition.<br>
/// <dt><i>Sharded Cluster</i>
/// <dd>A set of InterSystems IRIS instances configured to work together to support <i>sharding</i>.
/// A <i>sharded cluster</i> is comprised of one <i>shard master</i>, one or more 
/// <i>shard servers</i>, each of which hosts one or more <i>shards</i> that are assigned
/// to the <i>master namespace</i> hosted on the shard master, and zero or more 
/// <i>master app servers</i>, across which applications can be load balanced.
/// <dt><i>Shard Master</i>
/// <dd>A InterSystems IRIS instance, or a mirrored pair of InterSystems IRIS instances,
/// which hosts a <i>master namespace</i>. The set of InterSystems IRIS instances
/// comprising a <i>sharded cluster</i> consists of the <i>shard master</i> itself, the set of 
/// <i>shard server</i> instances hosting <i>shards</i> assigned to the <i>master namespace</i>,
/// and any <i>shard app servers</i> that have been configured with the <i>shard master</i> as
/// their data server, and with a namespace whose globals and routine databases are mapped to
/// those of the <i>master namespace</i> on
/// the <i>shard master</i>.  A single InterSystems IRIS instance can host more than one <i>master 
/// namespace</i>, in which case each of these <i>master namespaces</i> defines a separate
/// <i>sharded cluster</i>, and the <i>shard master</i> instance participates in each of these
/// <i>sharded clusters</i>.  If a <i>shard master</i> is mirrored, then the globals and
/// routine databases of each <i>master namespace</i> must be mirrored.<br>
/// <dt><i>Shard Server</i>
/// <dd>A InterSystems IRIS instance, or a mirrored pair of InterSystems IRIS instances, which hosts one or 
/// more <i>shards</i> (either <i>data shards</i>, <i>query shards</i>, or both).<br>
/// <dt><i>Master App Server</i>
/// <dd>A InterSystems IRIS instance that is configured as an ECP application server with
/// the <i>shard master</i> as its data server, and hosting a namespace whose globals and
/// routine databases are mapped to those of the <i>master namespace</i> on the <i>shard master</i>.
/// Any sharding operation (including configuration, data definition, and data manipulation) that
/// can be performed in the <i>master namespace</i> on the <i>shard master</i> can be performed
/// identically in the namespace on a <i>master app server</i> whose database are mapped to
/// those of the <i>master namespace</i>.  The sole exception: the first-ever call to
/// <method>AssignShard</method> for a given <i>master namespace</i> must be made locally on the
/// <i>shard master</i> (and will return an error if attempted on a namespace whose globals
/// database is not local).
/// <br>
/// <dt><i>Master Namespace</i>
/// <dd>A InterSystems IRIS namespace which has been assigned one or more <i>shards</i>, and can therefore contain
/// sharded (that is, horizontally partitioned) tables. Other than the added ability to contain 
/// sharded tables, a master namespace has all of the characteristics
/// and capabilities of an "ordinary" namespace (for example, it can contain tables that are not sharded;
/// it can have mappings to globals residing in databases other than its default globals database;
/// globals in its default globals database can be transparently accessed from a namespace on an ECP
/// app server, whose globals database is a remote database mapped to the globals database of the
/// master namespace;
/// etc.). Any namespace that is not a <i>shard namespace</i> can become a master namespace 
/// by being assigned one or more <i>shards</i>.<br>
/// <dt><i>Shard Namespace</i>
/// <dd>A InterSystems IRIS namespace which has been designated to play the role of <i>shard</i>, by
/// being specified (by host and port of the InterSystems IRIS instance on which it resides, and the name of 
/// the namespace) in a call to <method>AssignShard</method>.  <i>Shard namespaces</i> are transparent to 
/// end users of sharding, who access sharded tables via a <i>master namespace</i>, without needing to
/// be aware of the names or locations of the <i>shard namespaces</i> assigned to that <i>master
/// namespace</i>.  <i>Shard namespaces</i> are visible to users who administer and configure 
/// sharding via this $SYSTEM.Sharding API.  As namespaces, they are created and managed in the same
/// ways as any other namespaces; their roles as <i>shards</i> are managed using this $SYSTEM.Sharding API. A
/// namespace cannot be both a <i>master namespace</i> and a <i>shard namespace</i>.  As recommended best practice,
/// <i>shard namespaces</i> should not be accessed directly by end users, and should not be used for 
/// any purpose other than as <i>shards</i> of the <i>master namespaces</i> to which they are assigned.<br>
/// <dt><i>Shard</i>
/// <dd>A partition of a <i>master namespace</i>, that contains one horizontal partition 
/// of each sharded table in the <i>master namespace</i> to which the <i>shard</i> is
/// assigned. A shard is implemented as as <i>shard namespace</i>. 
/// A <i>shard</i> is either a <i>data shard</i> or a <i>query shard</i>.  A <i>data shard</i> may or
/// may not be a <i>mirrored shard</i>, but a <i>query shard</i> is never a <i>mirrored shard</i>.<br>
/// Note: The term <i>shard</i> can also be used to refer to a horizontal partition of an individual
/// sharded table, but the context of the $SYSTEM.Sharding API, it refers to a partition of the <i>master namespace</i>.<br>
/// <dt><i>Data Shard</i>
/// <dd>A <i>shard</i> in which data is stored for one horizontal partition of each sharded table in the
/// <i>master namespace</i> to which the data shard is assigned.  A <i>data shard</i> may or may not 
/// be a <i>mirrored shard</i>. If it is a <i>mirrored shard</i>, its default globals database is a mirrored database.
/// Otherwise, its default globals database is a non-mirrrored
/// local database, or a remote database mapped to a non-mirrored database.  <i>Data shards</i> are
/// assigned a shard number 1 through number of shards, in the order that they are assigned calling
/// <method>AssignShard</method>.<br>
/// <dt><i>Query Shard</i>
/// <dd>A <i>shard</i> which does not store data, but provides remote access via ECP to the data stored
/// in a <i>data shard</i> to which it is assigned.  Zero or more <i>query shards</i> may be assigned to
/// each <i>data shard</i>, by specifying the shard number of corresponding <i>data shard</i> in a call to
/// <method>AssignShard</method>.  A <i>shard namespace</i> used as a <i>query shard</i> must have
/// as its default globals database a remote database that is mapped to the default globals database
/// of the <i>data shard</i> to which the <i>query shard</i> is assigned.  When SQL operations are executed
/// on sharded tables, read-only queries are automatically executed on <i>query shards</i> for any <i>shards</i> that 
/// have one or more <i>query shards</i> assigned to them, but are executed on <i>data shards</i> if
/// those <i>data shards</i> have no <i>query shards</i> assigned to them.  If more than one <i>query shard</i> has been
/// assigned to a <i>shard</i>, queries are automatically load balanced among them. Write operations
/// (insert, update, delete, and DDL operations) are automatically executed on <i>data shards</i>.
/// <i>Query shards</i> can be used to minimize interference betwe en query and data ingestion work
/// loads, and to increase the band width of a sharded configuration for high volume multi-user 
/// query work loads. <br>
/// <dt><i>Mirrored Shard</i>
/// <dd>A <i>data shard</i> whose default globals database is mirrored. Use of <i>mirrored shards</i>
/// provides high availability for sharded configurations, with transparent failover between mirror
/// failover members and transparent completion of query operations, in the event of failover of one
/// or more <i>shards</i> occurring during execution of a query.  When configuring <i>shard namespaces</i>
/// for <i>mirrored shards</i>, the <i>shard namespace</i> for a given <i>shard</i> must have the same
/// name on both mirror failover members, and its default globals database must be the same mirrored
/// database.<br>
/// </dl>
/// <p><b>API Usage</b>
/// <p>A InterSystems IRIS instance is enabled to act as a shard master or shard server by calling 
/// <method>EnableSharding</method>.
/// <p>The set of shards belonging to a master namespace is defined by making repeated calls to
/// <method>AssignShard</method>, one call for each shard.
/// <p>Once shards have been assigned, <method>VerifyShards</method> can be called to verify
/// that they are reachable and correctly configured.
/// <p>If additional shards are assigned to a namespace that already contains sharded tables,
/// and the new shards can't be reached for automatic verification during the calls to
/// <method>AssignShard</method>, <method>ActivateNewShards</method> can be called to
/// activate them, once they are reachable.
/// <p>After new shards are assigned, existing sharded data can be rebalanced across all shards, including new ones, by calling <method>Rebalance</method>.
/// <p>A shard can be removed from the set belonging to a master namespace by calling
/// <method>DeassignShard</method>.
/// <p>An existing data shard can be assigned a different shard namespace address by calling
/// <method>ReassignShard</method>.
/// <p>All the shards assigned to a master namespace can be listed by calling <method>ListShards</method>.
/// <p>A non-default IP address or DNS name for connecting an InterSystems IRIS instance to other instances of sharded 
/// cluster can be specified by calling <method>SetNodeIPAddress</method>.
/// <p>Sharding configuration options can be set by calling <method>SetOption</method>,
/// and their values can be retrieved by calling <method>GetOption</method>.                                                                                   
Class %SYSTEM.Sharding Extends %SYSTEM.Help [ System = 4 ]
{

/// Enables the current InterSystems IRIS instance to act as a shard master or shard server.
/// <p>This API call provides a convenient way to perform several configuration steps which would otherwise
/// need to be performed separately:
/// <li>Enables the ECP service.
/// <li>Sets the config options MaxServers and MaxServerConn.
/// <li>Optionally enables the sharding service, so this InterSystems IRIS instance can act as a shard server.
/// <li>Optionally configures a list of allowed connections for the sharding and ECP services.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MaxConn</i>
/// <dd>Maximum number of ECP connections needed for this InterSystems IRIS instance to communicate with other 
/// instances in this sharded cluster (default 64). If non-zero, this must be greater than or equal to
/// the total number of InterSystems IRIS instances participating in the sharded cluster, but must be at least 2 (even if there is only one instance).<br>
/// The value specified for <i>MaxConn</i> is used to set the config options MaxServers and MaxServerConn. Specifying 0 means "do not change these config options", 
/// in which case they are assumed to be already set to appropriate values.<br>
/// <dt><i>EnableAsShardServer</i>
/// <dd>TRUE(1)/FALSE(0).  If <i>EnableAsShardServer</i> is TRUE(1) (the default), the sharding service 
/// (%Service_Sharding) is enabled
/// for this InterSystems IRIS instance, enabling it to act as a shard server or a shard master.  If <i>EnableAsShardServer</i> is
/// FALSE(0), the sharding service is disabled for this instance, enabling this instance to act as a shard master, but not as
/// a shard server.<br>
/// <dt><i>AllowedConnections</i>
/// <dd>List of hosts allowed to connect to this InterSystems IRIS instance in its role as shard server, specified 
///  as a semi-colon-separated list of IP addresses or hostnames.  If this list is specified, the listed hosts are
///  configured as the allowed incoming connections for the sharding service and the ECP service (replacing any
///  lists of allowed connections previously configured for those services); else the sharding
///  and ECP services are configured
///  to have no lists of allowed incoming connections (this causes there to be
///  no restriction on which hosts may connect to this InterSystems IRIS instance via these services).   
///  If <i>AllowedConnections</i> is specified, the list should include all hosts participating in the 
///  sharded cluster as masters, shard servers, master app servers, or query 
///  shard servers, and should include both failover members of any mirrored pairs.  <br>Note: 
///  <i>AllowedConnections</i> only needs to be specified on InterSystems IRIS instances playing the role of shard server (either 
///  data or query shard server). If <i>EnableAsShardServer</i> is FALSE(0), the ECP service's list of allowed connections is not modified.
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>A user must have administrative privileges in order to execute this API call.
/// <li>After this API call, the InterSystems IRIS instance must be restarted for all of the changes to take 
/// effect.
/// <li>This API call affects an entire InterSystems IRIS instance. If this instance participates in more than one
/// sharded cluster (e.g. contains more than one master namespace, or shards belonging to more than
/// one master namespace), the <i>MaxConn</i> and <i>AllowedConnections</i> arguments must be sufficient for
/// all of the clusters in which this instance participates.
/// </ul></dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Enable as shard server or shard master, MaxServers=MaxServerConn=64, no 
/// restriction of allowed connections:<br>
/// set status = $SYSTEM.Sharding.EnableSharding()
/// <li>Enable as shard server or shard master, MaxServers=MaxServerConn=3, two allowed connections specified:<br>
/// set status = $SYSTEM.Sharding.EnableSharding(3,1,"172.16.120.119;172.16.120.120")
/// <li>Enable as shard master only, MaxServers=MaxServerConn=64:<br>
/// set status = $SYSTEM.Sharding.EnableSharding(,0)
/// </ul>
ClassMethod EnableSharding(MaxConn As %Integer = 64, EnableAsShardServer As %Boolean = 1, AllowedConnections As %String = "") As %Status
{
	$$$SSCheckShardingLicense
 	return $$enableSharding^%SYS.SHARDSRV(MaxConn,EnableAsShardServer,AllowedConnections)
}

/// Assigns a shard to a master namespace.
/// <p>This API call can be used to assign a data shard or a query shard.
/// <p>A data shard can be a namespace on a single InterSystems IRIS instance, or it can be a namespace
/// whose globals database is mirrored.
/// <p>A query shard must be a namespace on a single InterSystems IRIS instance, whose globals database is
/// a remote database mapped to the globals database of the corresponding data shard.  When
/// assigning a query shard, the <i>ShardNumber</i> of the corresponding data shard must be
/// specified, and that data shard must already have been assigned.
/// <p>New data shards cannot be assigned if any sharded tables with user-defined shard keys
/// already exist in the specified master namespace. If new data shards are assigned when
/// sharded tables without user-defined shard keys already exist, this API call attempts to
/// connect to the newly assigned shards to verify them before they are activated; if this
/// fails (either because the new shards are not reachable, or because they fail verification),
/// this API call returns an error indicating that <method>ActivateNewShards</method> must be called to
/// activate the new shards. 
/// <p>New query shards can be assigned at any time, regardless of whether sharded tables 
/// already exist.
/// <p>If a data shard has been flagged for pending removal by calling <method>DeassignShard</method> while sharded
/// tables exist, and the shard's removal has not yet been completed by calling <method>Rebalance</method>, the 
/// pending removal can be cancelled by calling <b>AssignShard</b>.  In that case, if the shard is mirrored, it
/// optional whether to specify the <i>ShardMirrorName</i>, <i>ShardBackupHost</i>, and <i>ShardBackupPort</i>
/// parameters, but an error is returned if they are specified, and do not match the actual mirror name, or the
/// host and port of the shard's current backup failover member.  Call <method>ListShards</method> to determine
/// whether a shard is flagged for pending removal.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace to which the shard is assigned. Defaults to the current namespace.<br>
/// <dt><i>ShardHost</i>
/// <dd>The machine hosting the shard namespace, specified by hostname or IP address.<br>
/// <dt><i>ShardPort</i>
/// <dd>The default port (Super Server port) of the InterSystems IRIS instance hosting the shard namespace.<br>
/// <dt><i>ShardNamespace</i>
/// <dd>The namespace being assigned as a shard.<br>
/// <dt><i>ShardNumber</i>
/// <dd>Specifying a <i>ShardNumber</i> indicates that this shard is being assigned as a query
/// shard, corresponding to the data shard with the specified <i>ShardNumber</i>, which must already 
/// have been assigned.  Do not specify a value for <i>ShardNumber</i> when assigning a data shard.
/// <br>
/// <dt><i>ShardMirrorName</i>
/// <dd>For a mirrored shard, <i>ShardMirrorName</i> specifies the 
/// mirror name (also known as mirror set name) of the mirror hosting the shard.  This parameter must
/// be specified when assigning a mirrored shard, and must not be specified otherwise.<br>
/// <dt><i>ShardBackupHost</i>
/// <dd>For a mirrored shard, the machine hosting the backup failover member of the mirror, specified
/// by hostname or IP address. This parameter must be specified when assigning a mirrored shard,
/// and must not be specified otherwise.<br>
/// <dt><i>ShardBackupPort</i>
/// <dd>For a mirrored shard, the default port (Super Server port) of the backup failover member of the 
/// mirror. This parameter must be specified when assigning a mirrored shard, and must not be
/// specified otherwise.
/// <dt><i>ShardVIP</i>
/// <dd>For a mirrored shard, the Virtual IP address of the mirror, if one has been configured (optional).
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>This API call does not create or configure InterSystems IRIS instances, namespaces, mirrors, or remote database
/// mappings, it just assigns specified namespaces on specified single or mirrored instances to play 
/// roles as shards of a specified master namespace.  The specified namespaces, instances, mirrors,
/// and remote database mappings must be configured separately using appropriate APIs in Management Portal
/// or in classes in the Config package, either before or after calling <method>AssignShard</method>. The
/// requisites are:
/// <dd><li>Create InterSystems IRIS instance and namespace specified by <i>ShardHost</i>, <i>ShardPort</i>, and <i>ShardNamespace</i>.
/// <li>For mirrored shard, create InterSystems IRIS instances specified by <i>ShardHost</i> and <i>ShardPort</i>, and
/// by <i>ShardBackupHost</i> and <i>ShardBackupPort</i>, and configure them as the failover members of a 
/// mirrored set. (Note: It doesn't matter which one is actually the primary failover member at the
/// time <method>AssignShard</method> is called.) Create namespace specified by <i>ShardNamespace</i> on both failover 
/// members, with its globals database configured as a mirrored database.
/// <li>For query shard, create namespace specified by <i>ShardNamespace</i> with remote database
/// mapped to the globals database of the namespace of the corresponding data shard.
/// <li>Enable sharding on the shard instance, by calling <method>EnableSharding</method>. 
/// For mirrored shard, enable sharding on both failover members.
/// </dd>
/// <li>This API call returns an error if the namespace specified by <i>ShardHost</i>, <i>ShardPort</i>, 
/// and <i>ShardNamespace</i>, or by <i>ShardBackupHost</i>, <i>ShardBackupPort</i>, and <i>ShardNamespace</i>, 
/// has already been assigned as a data or query shard, or as the backup of a mirrored data shard, or if
/// it is the same as the master namespace.
/// <li>By default, this API call does not attempt to connect to the newly assigned shard to confirm that
/// it is reachable and is correctly configured, except in the case where a data shard is assigned and sharded
/// tables already exist.  This call can be made to automatically verify all assigned shards by 
/// calling <code>SetOption(masterNamespace,"AutoVerify",1)</code> (where <i>masterNamespace</i> is set
/// to the appropriate master namespace), or verification can be performed in a separate call to <method>VerifyShards</method>.
/// <li>Shard numbers are assigned to data shards sequentially, starting from 1, in the order they are
/// assigned. The shard number of a given shard can be determined by calling <method>ListShards</method>. If
/// shards are de-assigned by calling <method>DeassignShard</method>, the shard numbers of any high-numbered
/// shards are decremented, so that there are never any gaps in the sequence.
/// <li>As a convenience, "localhost" can be specified as the value of <i>ShardHost</i>, for a shard 
/// that resides on the current machine. This is always translated internally to the actual hostname or IP 
/// address. Sharding never uses the "loop-back" IP address 127.0.0.1.
/// </ul>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Assign a single-instance data shard:<br>
/// set status = $SYSTEM.Sharding.AssignShard("MASTER","machine1",1972,"SHARD1")
/// <li>Assign a mirrored shard to the current namespace:<br>
/// set status = $SYSTEM.Sharding.AssignShard(,"machine2",1972,"SHARD2",,"MIRROR1","machine3",1972,"123.45.67.89")
/// <li>Assign a query shard:<br>
/// set status = $SYSTEM.Sharding.AssignShard("MASTER","machine4",1972,"SHARD1",1)
/// </ul>
ClassMethod AssignShard(MasterNamespace As %String = {$namespace}, ShardHost As %String, ShardPort As %Integer, ShardNamespace As %String, ShardNumber As %Integer = "", ShardMirrorName As %String = "", ShardBackupHost As %String = "", ShardBackupPort As %Integer = "", ShardVIP As %String = "") As %Status
{
	$$$SSCheckShardingLicense
	$$$SSCheckClusterVersion(MasterNamespace)
	if ($g(ShardHost)="")||($g(ShardPort)="")||($g(ShardNamespace)="") {
		// Other arguments are checked in called methods
		return $$$ERROR($$$InvalidArgument)
	}
	elseif ShardMirrorName'=""&&(ShardNumber'="") {
		return $$$ERROR($$$SHMQueryShardCannotBeMirrored)
	}
	s ShardHost=$zconvert(ShardHost,"L")
	s:ShardBackupHost'="" ShardBackupHost=$zconvert(ShardBackupHost,"L")
	try {
		new $namespace
		s $namespace=MasterNamespace
		if ShardMirrorName'="" {
			s status=##class(%BigData.ShardingManager).%AssignMirroredShard(MasterNamespace, ShardMirrorName, ShardHost, ShardPort, ShardBackupHost, ShardBackupPort, ShardNamespace,, ShardVIP)

		}
		elseif ShardNumber'="" {
			s status=##class(%BigData.ShardingManager).%AssignShardAppServer(MasterNamespace, ShardNumber, ShardHost, ShardPort, ShardNamespace)
		}
		else {
			s status=##class(%BigData.ShardingManager).%AssignShards(MasterNamespace,$lb(ShardHost,ShardPort,ShardNamespace))
		}
		s:status=$$$OK&&(+$g($$$SSGlobal($$$SSAutoVerifySubscript))=1) status=..VerifyShards(MasterNamespace)
	}
	catch ex {
		s status=ex.AsStatus()
	}
	return status
}

/// Re-assigns an existing data shard.  This API call assigns a different shard namespace (specified by
/// host, port, and namespace) to a shard number to which a data shard has previously been assigned.
/// <p>The newly specified shard namespace can be a namespace on a single InterSystems IRIS instance, or it can be a namespace
/// whose globals database is mirrored. It is expected to contain identical data to the namespace previously
/// assigned to the specified <i>ShardNumber</i>.  The caller is responsible for ensuring this.
/// <p>This API call has the following use cases:
/// <ul>
/// <li>The globals database of the shard namespace is being relocated on a different InterSystems IRIS instance
/// and/or host machine.  The move itself is done outside of this API, and can be done in two general ways:
/// <p><dd><li>Dismount the source database, copy its IRIS.DAT file to its target location, and configure
/// the new shard namespace with a globals database configured to use the copied IRIS.DAT file. This requires
/// a maintenance window during which no applications access sharded tables in this master namespace.
/// <p><li>Temporarily configure the source and target InterSystems IRIS instances as a mirrored set, with
/// the target instance as backup failover member, backup the source database to the target
/// database, and then promote the target instance to primary failover member. 
/// Applications can continue to access sharded tables throughout this process. 
/// </dd>
/// <p>The source and target versions of the relocated shard can each either be mirrored or not. If the 
/// target is mirrored, the relocation can be done in multiple steps: first call ReassignShard to 
/// specify the target shard as a namespace on a single InterSystems IRIS instance, then after configuring
/// the target as a mirror and backing up the target database to the backup failover member, call ReassignShard
/// to re-specify the target shard as a mirrored namespace.  If the relocation is done during a maintenance 
/// window, then ReassignShard only needs to be called once, after the target mirror is configured and
/// the target database is up to date on both failover members.
/// <p>The ability to relocate shards can be used to allow for future horizontal scaling, by initially
/// configuring more shards than the number of of host machines, which multiple shards on each machine
/// (each hosted on a different 
/// InterSystems IRIS instance), and later adding machines to the sharded cluster, and relocating shards
/// to separate host machines.
/// <li>A shard that was previously not mirrored is being reconfigured to be mirrored.  In this case,
/// specify the <i>ShardHost</i>, <i>ShardPort</i>, and <i>ShardNamespace</i> of the current shard
/// namespace, specify the <i>ShardMirrorName</i> of the newly configured mirror, and specify the
/// <i>ShardBackupHost</i>, <i>ShardBackupPort</i>, and (optionally) <i>ShardVIP</i> of the newly
/// configured backup failover member.
/// <p><li>A shard that was previously mirrored is being reconfigured as not mirrored, leaving what was
/// previously the primary failover member as the sole instance hosting the shard.  In this case,
/// specify the <i>ShardHost</i>, <i>ShardPort</i>, and <i>ShardNamespace</i> of the current primary
/// failover member, and do not specify values for <i>ShardMirrorName</i>, <i>ShardBackupHost</i>, 
/// <i>ShardBackupPort</i>, or <i>ShardVIP</i>.
/// <p><li>A new backup failover member is being specified for a mirrored shard, following failure and
/// replacement of the previous backup failover member. In this case,
/// specify the <i>ShardHost</i>, <i>ShardPort</i>, and <i>ShardNamespace</i> of the current primary
/// failover member, specify current <i>ShardMirrorName</i>, and specify the
/// <i>ShardBackupHost</i>, <i>ShardBackupPort</i>, and (optionally) <i>ShardVIP</i> of the newly
/// configured backup failover member.
/// </ul>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace to which the shard is assigned. Defaults to the current namespace.<br>
/// <dt><i>ShardHost</i>
/// <dd>The machine hosting the shard namespace, specified by hostname or IP address.<br>
/// <dt><i>ShardPort</i>
/// <dd>The default port (Super Server port) of the InterSystems IRIS instance hosting the shard namespace.<br>
/// <dt><i>ShardNamespace</i>
/// <dd>The namespace being assigned as a shard.<br>
/// <dt><i>ShardNumber</i>
/// <dd>The shard number to which a new shard namespace is assigned. There must already be a data
/// shard assigned to this shard number.
/// <br>
/// <dt><i>ShardMirrorName</i>
/// <dd>For a mirrored shard, <i>ShardMirrorName</i> specifies the 
/// mirror name (also known as mirror set name) of the mirror hosting the shard.  This parameter must
/// be specified when assigning a mirrored shard, and must not be specified otherwise.<br>
/// <dt><i>ShardBackupHost</i>
/// <dd>For a mirrored shard, the machine hosting the backup failover member of the mirror, specified
/// by hostname or IP address. This parameter must be specified when assigning a mirrored shard,
/// and must not be specified otherwise.<br>
/// <dt><i>ShardBackupPort</i>
/// <dd>For a mirrored shard, the default port (Super Server port) of the backup failover member of the 
/// mirror. This parameter must be specified when assigning a mirrored shard, and must not be
/// specified otherwise.
/// <dt><i>ShardVIP</i>
/// <dd>For a mirrored shard, the Virtual IP address of the mirror, if one has been configured (optional).
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>This API call does not create or configure InterSystems IRIS instances, namespaces, or mirrors, or
/// copy, backup, mount, or dismount databases.  These operations must be performed 
/// separately using appropriate APIs in Management Portal
/// or in classes in the Config package, either before or after calling <method>ReassignShard</method>. 
/// <li>If any query shards have previously been configured and assigned to the <i>ShardNumber</i> 
/// that is being re-assigned, they must be re-configured so that their globals databases are mapped
/// to the re-configured database of the data shard.  This does not require de-assigning or re-assigning
/// the query shards through this API, since this API associates query shards with data shards by shard 
/// number, not by database mappings.
/// <li>This API call returns an error if the namespace specified by <i>ShardHost</i>, <i>ShardPort</i>, 
/// and <i>ShardNamespace</i>, or by <i>ShardBackupHost</i>, <i>ShardBackupPort</i>, and <i>ShardNamespace</i>, 
/// has already been assigned as a data shard, or as the backup of a mirrored data shard, with a shard
/// number other than the specified <i>ShardNumber</i>, or if it has been assigned as a query shard with
/// any shard number.
/// <li>By default, this API call does not attempt to connect to the re-assigned shard to confirm that
/// it is reachable and is correctly configured .  This call can be made to automatically verify all assigned shards by 
/// calling <code>SetOption(masterNamespace,"AutoVerify",1)</code> (where <i>masterNamespace</i> is set
/// to the appropriate master namespace), or verification can be performed in a separate call to <method>VerifyShards</method>.
/// <li>The <i>ShardNumber</i> to pass to this API call, if not already known,
/// can be determined by calling <method>ListShards</method>.
/// <li>As a convenience, "localhost" can be specified as the value of <i>ShardHost</i>, for a shard 
/// that resides on the current machine. This is always translated internally to the actual hostname or IP 
/// address. Sharding never uses the "loop-back" IP address 127.0.0.1.
/// </ul>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Re-assign shard number 1 as a single-instance data shard:<br>
/// set status = $SYSTEM.Sharding.ReassignShard("MASTER","machine1",1972,"SHARD1",1)
/// <li>Re-assign shard number 1 as a mirrored data shard:<br>
/// set status = $SYSTEM.Sharding.ReassignShard("MASTER","machine2",1972,"SHARD2",1,"MIRROR1","machine3",1972,"123.45.67.89")
/// </ul>
ClassMethod ReassignShard(MasterNamespace As %String = {$namespace}, ShardHost As %String, ShardPort As %Integer, ShardNamespace As %String, ShardNumber As %Integer, ShardMirrorName As %String = "", ShardBackupHost As %String = "", ShardBackupPort As %Integer = "", ShardVIP As %String = "") As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	if ($g(ShardHost)="")||($g(ShardPort)="")||($g(ShardNamespace)="")||($g(ShardNumber)="") {
		// Other arguments are checked in called methods
		return $$$ERROR($$$InvalidArgument)
	}
	s ShardHost=$zconvert(ShardHost,"L")
	s:ShardBackupHost'="" ShardBackupHost=$zconvert(ShardBackupHost,"L")
	try {
		new $namespace
		s $namespace=MasterNamespace
		s status=##class(%BigData.ShardingManager).%ReassignShard(MasterNamespace, ShardHost, ShardPort, ShardNamespace, ShardNumber, ShardMirrorName, ShardBackupHost, ShardBackupPort, ShardVIP)
		s:status=$$$OK&&(+$g($$$SSGlobal($$$SSAutoVerifySubscript))=1) status=..VerifyShards(MasterNamespace)
	}
	catch ex {
		s status=ex.AsStatus()
	}
	return status
}

/// Reinitializes the internal mappings, connections, and cluster metadata of a sharded cluster which has been
/// "cloned".
/// <p>A sharded cluster is cloned by copying its master and shard databases to a new set of IRIS instances, and
/// reassigning the shards to the hosts, ports, and namespaces of their new locations. This method is called as the
/// final step of the process.
///  
/// <p><b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace of the cluster to be reinitialized.<br>
/// <dt><i>IgnoreMappings</i>
/// <dd>Flag indicating whether to ignore any user-defined global, routine, or package mappings that were defined
/// in the master namespace of the original cluster that is being cloned. By default, this method returns an error
/// if there were user-defined mappings in the original master namespace, because this might indicate that data
/// accessed via these mappings will be unavailable in the targetcluster.  If 1 is specified for <i>IgnoreMappings</i>, 
/// user-defined mappings in the original master namespace don't cause an error to be returned.
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Cluster cloning usage:</b>
/// <ul>
/// <li>Call <method>GetConfig</method> to get information about the directory paths of the master and shard databases, 
/// which need to be copied to the new cluster.
/// <li>Shut down the original cluster, and copy or backup the master and shard databases, making sure to keep track of 
/// which shard database belongs with which shard number.  NOTE: Whether or not the original cluster is mirrored, the 
/// target cluster will not be mirrored initially.  Therefore, only the databases from one failover member of each mirrored node need to be copied. 
/// <li>Create IRIS instances of the target cluster, making sure to keep track of which target instance corresponds to 
/// which shard number of the original cluster. (NOTE: Do not create instances for compute nodes or mirror backups or DR 
/// asyncs - these can be added later if desired.)  In each instance, create a namespace to be the shard namespace, and 
/// cause its globals database to be the copied shard database from the corresponding node in the original cluster (this 
/// can be done by restoring a backup of the original database, or by copying the IRIS.DAT file - any approach supported 
/// by IRIS for copying a database can be used).  In whichever target instance corresponds to the original instance 
/// containing the master namespace and database, create a namespace to be the master namespace of the target cluster, 
/// and cause its globals database and (if different) routines database to be the copied master databases from the 
/// original cluster.
/// <li>In the master instance of the target cluster, call <method>ReassignShard</method> once per shard, to specify the 
/// hostname or IP address, Super Server port, and namespace of each target shard, making sure to specify the correct shard 
/// numbers to correspond to the original cluster.
/// <li>Call <method>Reinitialize</method>.  This verifies that the target cluster is of a compatible version, sets up all 
/// the mappings, ECP connections, and metadata needed to activate the target cluster, and automatically calls 
/// <method>VerifyShards</method> to complete activation and confirm that the configuration is correct.
/// <li>NOTE: If the original master namespace has user-defined global, routine, or database mappings which need to be
/// duplicated in the target cluster, create equivalent mappings in the target master namespace. Either copy the
/// databases containing the items pointed to by the mappings, from the original cluster to the target cluster, or define 
/// the mappings in the target master namespace to point to the original databases containing the mapped items.
/// </ul>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Reinitialize the cluster whose master namespace is "MASTER", returning an error if any user-defined mappings 
/// existed in the original master namespace:<br>
/// set status = $SYSTEM.Sharding.Reinitialize("MASTER")
/// <li>Reinitialize the cluster whose master namespace is "MASTER", ignoring any user-defined mappings that existed
/// in the original master namespace:<br>
/// set status = $SYSTEM.Sharding.Reinitialize("MASTER", 1) 
/// </ul>
ClassMethod Reinitialize(MasterNamespace As %String = {$namespace}, IgnoreMappings As %Boolean = 0) As %Status
{
	$$$SSCheckShardingLicense
	$$$SSCheckClusterVersion(MasterNamespace)
	return $$reinitializeCluster^%SYS.SHARDSRV(MasterNamespace,IgnoreMappings)
}

/// De-assigns a shard from a master namespace to which it had previously been assigned. This
/// removes the shard from the set of shards belonging to the master namespace.
/// <p>This API call can be used to de-assign a data shard or a query shard.
/// <p>If a data shard is de-assigned while any sharded tables exist, the data shard is not immediately removed,
/// but is flagged for pending removal.  The next call to <method>Rebalance</method> will move all sharded data 
/// from any shards that are flagged for pending removal, to other data shards, and will complete the process of
/// removing the shards that are pending removal.  The last remaining data shard in a cluster may not be de-assigned.
/// <p>When a query shard is de-assigned, it is always immediately removed.
/// <p>When de-assigning a data shard to which any query shards are currently assigned, those
/// query shards are automatically de-assigned as well.
/// <p>When de-assigning a mirrored data shard, the host and port of either failover member may be
/// specified.  In either case, both failover members are de-assigned as shards.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace to which the shard is currently assigned. Defaults to the current namespace.<br>
/// <dt><i>ShardHost</i>
/// <dd>The machine hosting the shard namespace, specified by hostname or IP address.<br>
/// <dt><i>ShardPort</i>
/// <dd>The default port (Super Server port) of the InterSystems IRIS instance hosting the shard namespace.<br>
/// <dt><i>ShardNamespace</i>
/// <dd>The namespace being de-assigned as a shard.<br>
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>De-assigning a shard does not delete the shard namespace, or any data that may have been
/// created in that namespace while it was serving as a shard.  It simply causes that namespace to no
/// longer serve as a shard of the specified master namespace, and makes the namespace available to be
/// assigned as a shard of different master namespace.  When a data shard is de-assigned,
/// the shard count is decremented, and 
/// the shard numbers of any higher-numbered shards are decremented, so that there are no gaps 
/// in the sequence of shard numbers.  When a query shard is de-assigned, this simply reduces by one the
/// number of query shards assigned to the data shard to which that query shard had been assigned.
/// <li>
/// Query shards can be de-assigned at any time, just as they can be assigned at any time.  This provides 
/// a dynamic means of adjusting the query throughput capacity of a sharded cluster as multi-user workloads grow or
/// shrink. Note that this does not change the degree of parallelism for the execution of an individual query
/// (which always equals the number of data shards), but it changes the multi-user throughput by enabling 
/// different concurrent queries to execute on different sets of query shards.  When a query shard is
/// de-assigned, it continues to be used by any active user connections already in progress, but is not used
/// by any new user connections. Therefore, query shards can safely be de-assigned while query applications
/// are running.
/// <li>When a data shard is flagged for pending removal, due to calling <b>DeassignShard</b> while sharded tables exist,
/// the pending removal can be cancelled by calling <method>AssignShard</method>.  Call <method>ListShards</method> 
/// to determine whether a shard is currently flagged for pending removal.
/// <li>This API call returns an error if the the shard specified by <i>ShardHost</i>, <i>ShardPort</i>, and
/// <i>ShardNamespace</i> is not currently assigned to the specified master namespace as either a query
/// shard, a data shard, or either failover member of a mirrored data shard.
/// </ul></dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>De-assign a shard from a specified master namespace:<br>
/// set status = $SYSTEM.Sharding.DeassignShard("MASTER","machine1",1972,"SHARD1")
/// <li>De-assign a shard from the current namespace:<br>
/// set status = $SYSTEM.Sharding.DeassignShard(,"machine1",1972,"SHARD1")
/// </ul>
ClassMethod DeassignShard(MasterNamespace As %String = {$namespace}, ShardHost As %String, ShardPort As %Integer, ShardNamespace As %String) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	if ($g(ShardHost)="")||($g(ShardPort)="")||($g(ShardNamespace)="") {
		// Other arguments are checked in called methods
		return $$$ERROR($$$InvalidArgument)
	}
	try {
		return ##class(%BigData.ShardingManager).%RemoveShards(MasterNamespace,$lb(ShardHost,ShardPort,ShardNamespace))
	}
	catch ex {
		return ex.AsStatus()
	}
}

/// Verifies that assigned shards are reachable and are correctly configured.
/// <p>Verifies either all shards that have been assigned to a specified master namespace (the
/// simplest and recommended usage), or a specified data shard, or a specified query shard of a
/// specified data shard.
/// <p>For each shard verified, this API call verifies the following, and returns a specific
/// error for each failure:
/// <li>The shard is reachable (the InterSystems IRIS instance hosting the shard is started, and can
/// be reached via TCP/IP).
/// <li>The ECP and sharding services are enabled on the instance hosting the shard.
/// <li>If the sharding service on that instance has a list of allowed incoming connections, the
/// host on which this API call is made is included in the list.
/// <li>The instance hosting the shard has the config parameters MaxServers and MaxServerConn set to
/// sufficiently high values for the currently assigned set of shards.  This checks for a value that is
/// at least as great as the total number of InterSystems IRIS instances participating in the sharded cluster, including the 
/// shard master and each additional instance that hosts one or more shards, but not including
/// any master app servers. For this purpose,
/// a mirror counts as one instance. (If there are any master app servers  participating in the sharded cluster,
/// the number of master app servers
/// must be added to the MaxServer and MaxServerConn settings on each instance in the sharded cluster,
/// beyond the minimum value that is checked by this API call.)
/// <li>The instance hosting the shard does not require restart due to changes having been made to the
/// CPF file and not yet activated.  (Note that changes to MaxServers and MaxServerConn require restart before
/// they are effective.)
/// <li>The shard namespace exists.
/// <li>The shard namespace is not the master namespace of some other sharded cluster, and has
/// not already been assigned as a shard of some other sharded cluster. (<method>AssignShard</method>
/// ensures that the same namespace is not assigned twice as a shard of the present sharded cluster.) 
/// <li>For query shards, the shard namespace has as its default globals database a remote database that
/// is mapped to the default globals database of the data shard to which the query shard is assigned.
/// <li>For mirrored shards, the instance assigned as primary failover member really is a mirror failover
/// member, and really does have, as its backup failover member, the instance assigned as backup failover
/// member (for this purpose, it does not matter which failover member is currently the primary; if 
/// the mirror is correctly configured, this API call transparently connects to whichever failover member
/// is currently the primary, and verifies that the other failover member's host and port were correctly
/// specified to <method>AssignShard</method>).
/// <br><br>
/// This API call also verifies that the master instance on which it is invoked has the ECP service enabled,
/// has sufficient values for the config parameters MaxServers and MaxServerConn, and does not require restart
/// due to changes not yet activated in the CPF file.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace whose shards are to be verified.  Defaults to the current namespace.<br>
/// <dt><i>ShardNumber</i>
/// <dd>The shard number of the shard to be verified (1 through number of data shards).  By default,
/// verifies all shards.<br>
/// <dt><i>QueryShardNumber</i>
/// <dd>Query shard number, among the query shards of the specified shard, of the shard to be verified.
/// <i>ShardNumber</i> must be specified if <i>QueryShardNumber</i> is specified. By default, verifies 
/// all query shards of the specified shard, or all query shards of all shards if <i>ShardNumber</i>
/// is not specified.<br>
/// <dt><i>ReturnFirstError</i>
/// <dd>TRUE(1)/FALSE(0). If <i>ReturnFirstError</i> is TRUE(1), this API call will return an error after the
/// first shard that fails verification.  If <i>ReturnFirstError</i> is FALSE(0) (the default), this
/// API call will attempt to verify all data shards, and if any of them fail verification, it will 
/// return a nested status including the error for each shard which failed verification.  If all
/// data shards are successfully verified, this API call with then attempt to verify all query shards,
/// and if any of them fail verfication, it will return a nested status including the error for each
/// query shard which failed verification.<br>
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call. If multiple shards fail verification, 
/// this is a nested status code indicating how many shards failed, which shards failed, and the specific error 
/// for each failed shard.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>The API call <method>AssignShard</method> can be made to automatically verify all assigned shards
/// by calling <code>SetOption(masterNamespace,"AutoVerify",1)</code> (where <i>masterNamespace</i> is set to the appropriate
/// master namespace). This has the advantage of avoiding the need for a separate
/// call to <method>VerifyShards</method>, but means that shard instances and namespaces must already be
/// reachable and correctly configured when calling <method>AssignShard</method>, or it will return 
/// verification errors, requiring a separate call to be made to <method>VerifyShards</method> once
/// all shard instances and namespaces have been correctly configured and made reachable.  Separating these two
/// API calls provides the option of configuring shard instances and namespaces either before or after
/// assigning them as shards.
/// </ul>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Verify all shards assigned to the current namespace:<br>
/// set status = $SYSTEM.Sharding.VerifyShards()
/// <li>Verify shard 1 assigned to namespace "MASTER":<br>
/// set status = $SYSTEM.Sharding.VerifyShards("MASTER",1)
/// <li>Verify the second query shard assigned to shard 3 of the current namespace:<br>
/// set status = $SYSTEM.Sharding.VerifyShards(,3,2)
/// <li>Verify all shards assigned to namespace "MASTER", but stop and return error for the first failure:<br>
/// set status = $SYSTEM.Sharding.VerifyShards("MASTER",,,1)
/// </ul>
ClassMethod VerifyShards(MasterNamespace As %String = {$namespace}, ShardNumber As %Integer = "", QueryShardNumber As %Integer = "", ReturnFirstError As %Boolean = 0) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	s recurse=(ShardNumber="" && (QueryShardNumber=""))
	return ##class(%BigData.ShardingManager).%VerifyShards(MasterNamespace,ShardNumber,QueryShardNumber,ReturnFirstError,,,recurse)
}

/// Lists the shards assigned to a specified master namespace, to the console or current device.
/// <p>The list contains a row for each shard, with information in columns under the following headings:
/// <li>Shard - the shard number (1 through number of shards).
/// <li>Host  - the hostname or IP address of the machine hosting the shard.
/// <li>Port  - the default port (Super Server port) of the InterSystems IRIS instance hosting the shard.
/// <li>Namespace- the shard namespace.
/// <li>Mirror - the mirror name, if the shard is mirrored.
/// <li>Role   - the shard's role:
/// <dd><li>(blank) - ordinary data shard.
/// <li>"Query" - query shard.
/// <li>"Primary" - primary failover member hosting mirrored shard.
/// <li>"Backup   - backup failover member hosting mirrored shard.
/// </dd>
/// <li>VIP       - VIP for mirrored shard, if one is configured. 
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace whose shards are listed. Defaults to the current namespace.<br>
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>This API call can be used to determine the shard number corresponding to a shard's host,
/// port, and namespace, for use as the <i>ShardNumber</i> parameter to <method>AssignShard</method>,
/// when assigning a query shard to a shard specified by shard number.
/// <li>For mirrored shards, indicated primary and backup members are those at the time of initial
/// shard assignment, or of the most
/// recent operation that required connecting to shards.  It is possible that the mirror has failed
/// over since then, in which case the indicated primary member is now the backup member and vice versa.
/// <li>Shards which have been assigned but not yet activated are listed 
/// with their shard number in parentheses and followed by an asterisk, for example "(25*)". (See 
/// <method>ActivateNewShards</method> for an explanation of activating shards.) 
/// <li>Shards which are pending removal, because they have been deassigned but <method>Rebalance</method> has not yet been 
/// called to moved sharded data from them to other shards, are listed 
/// with their shard number in brackets and followed by two asterisks, for example "[25**]".
/// </ul>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>List shards assigned to the current namespace to the console:<br>
/// set status = $SYSTEM.Sharding.ListShards()
/// <li>List shards asssigned to namespace "MASTER" to the file "shards.list" in the current directory:<br>
/// open "shards.list":"NW"<br>
/// use "shards.list" s status=$SYSTEM.Sharding.ListShards()<br>
/// close "shards.list"
/// </ul>
ClassMethod ListShards(MasterNamespace As %String = {$namespace}) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	return $$listShards^%SYS.SHARDSRV(MasterNamespace)
}

/// Retrieves configuration information about the sharded cluster to which the specified master or cluster namespace belongs.
/// <p>The information is returned in an array, passed by reference, under the following top-level subscripts:
/// <li> "Master" - Information about the cluster's master namespace and database, and the node on which they reside. For mirrored
/// clusters, this subscript appears as "Master:Primary" or "Master:Backup" to distinguish the two failover members.
/// <li> "Shard", <i>shard number</i> - Information about the shard with the indicated shard number. For mirrored clusters,
/// the shard number subscript includes "Primary", "Backup", or "DRAsync", separated from the shard number by a colon, for 
/// example "1:Primary".  For query shards, the shard number subscript includes "Query", separated from the shard number by
/// a colon. For DR async nodes or query shards, the subscript includes an additional colon-separated number, to distinguish
/// between multiple DR async nodes or query shards with the same shard number, for example "1:DRAync:2" or "3:Query:1".
/// <p>Configuration details for the master and each shard are returned under a second subscript (for the master) or
/// third subscript (for shards) with the following values:
/// <li>"GlobalsDatabase" (master only) - the name of the master globals database.
/// <li>"GlobalsDirectory" (master only) - the directory path of the master globals database.
/// <li>"RoutinesDatabase" (master only) - the name of the master routines database.
/// <li>"RoutinesDirectory" (master only) - the directory path of the master routines database.
/// <li>"Database" (shards only) - the name of the shard database.
/// <li>"Directory" (shards only) - the directory path of the shard database.
/// <li>"Host"  - the hostname or IP address of the machine hosting the node's InterSystems IRIS instance.
/// <li>"SuperServerPort" - the default port (Super Server port) of the InterSystems IRIS instance.
/// <li>"Namespace" - the name of the master or shard namespace.
/// 
/// </dd>
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Namespace</i>
/// <dd>Master or shard (i.e. cluster) namespace belonging to the sharded cluster whose configuration information 
/// is to be returned.<br>
/// <dt><i>ConfigInfo</i>
/// <dd>Array in which configuration information is returned, passed by reference.
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>For query shards, only the "Host", "SuperServerPort", and "Namespace" are returned.  For DR async nodes,
/// only the "Host" and "SuperServerPort" are returned.
/// </ul>
/// <p><b>Example</b>:
/// <ul>
/// <li>Get configuration information for the 2-shard cluster whose master namespace is "IRISDM", returned in the array <i>config</i>:
/// <p>set status = $SYSTEM.Sharding.GetConfig("IRISDM",.config)
/// <br>zw config
/// <br>config("Master","GlobalsDatabase")="IRISDM"
/// <br>config("Master","GlobalsDirectory")="/home/iris/mgr/irisdm/"
/// <br>config("Master","Host")="machine1"
/// <br>config("Master","Namespace")="IRISDM"
/// <br>config("Master","RoutinesDatabase")="IRISDM"
/// <br>config("Master","RoutinesDirectory")="/home/iris/mgr/irisdm/"
/// <br>config("Master","SuperServerPort")=1972
/// <br>config("Shard",1,"Database")="IRISSHARD"
/// <br>config("Shard",1,"Directory")="/home/iris/mgr/irisshard/"
/// <br>config("Shard",1,"Host")="machine1"
/// <br>config("Shard",1,"Namespace")="IRISCLUSTER"
/// <br>config("Shard",1,"SuperServerPort")=1972
/// <br>config("Shard",2,"Database")="IRISSHARD"
/// <br>config("Shard",2,"Directory")="/home/iris/mgr/irisshard/"
/// <br>config("Shard",2,"Host")="machine2"
/// <br>config("Shard",2,"Namespace")="IRISCLUSTER"
/// <br>config("Shard",2,"SuperServerPort")=1972
/// <ul>
ClassMethod GetConfig(Namespace As %String = {$namespace}, ByRef ConfigInfo) As %Status
{
	$$$SSCheckClusterVersion(Namespace)
	return $$getConfig^%SYS.SHARDSRV(Namespace,.ConfigInfo)
}

/// Sets a specified sharding configuration option to a specified value, within the scope of
/// a specified master namespace.
/// <p>All option values are integers, except in the case of MasterIPAddress.  The supported options, with their allowed values and
/// defaults, are as follows:<p>
/// <table border="1" title="Options">
/// <tr>
/// 	<th>Option Name</th><th>Description</th><th>Allowed Values</th><th>Default</th>
/// </tr>
/// <tr><td>AutoVerify</td><td><p>
/// 		Should <method>AssignShard</method> automatically call <method>VerifyShards</method>?
/// 			1: Yes. 0: No.
/// </p></td><td>0/1</td><td>No</td></tr>
/// <tr><td>ConnectTimeout</td><td><p>
/// 		Timeout when connecting to a shard, in seconds.
/// </p></td><td>&GT;=1</td><td>60</td></tr>
/// <tr><td>Debug</td><td><p>
/// 		Enables debug trace. 1: Enable all debug trace messages. Higher numbers: enable
///         increasingly selective debug trace. Only recommended when working directly with
///         InterSystems support.
/// </p></td><td>1-10</td><td>No debug trace.</td></tr>
/// <tr><td>DropIgnoreError</td><td><p>
/// 		Should errors occurring during DROP TABLE be ignored? 
/// 		    1: Yes. 0: No, return the error.
/// </p></td><td>0/1</td><td>No</td></tr>
/// <tr><td>MasterIPAddress</td><td><p>
/// 		IP address to use for master data server, rather than using DNS resolution on hostname.
/// 			<i>Deprecated, </i>use <method>SetNodeIPAddress</method> instead.
/// </p></td><td>Valid IP address</td><td>Use hostname.</td></tr>
/// <tr><td>MirrorConnectAttempts</td><td><p>
/// 		Number of times to retry connecting to a mirrored shard.
/// </p></td><td>&GT;=1</td><td>1</td></tr>
/// <tr><td>QuiesceAllowReads</td><td><p>
///         Should Backup.ShardedCluster.Quiesce allow reads? 1: Yes. 0: No, block reads as well 
///         as writes.
/// </p></td><td>0/1</td><td>No</td></tr>
/// <tr><td>RunQueriesAsync</td><td><p>
/// 		(DEPRICATED) Should queries be run asynchronously? 1: Yes.  0: No, run queries synchronously. 
///         This permits transparent completion in event of shard failover, when executing
///         queries on mirrored data shards, but it prevents cancelling queries and increases 
///         the risk of filling the IRISTEMP database. This option is depricated.  The recommended approach
///         for transparent query failover handling is to assign a query shard for each data shard.
/// </p></td><td>0/1</td><td>Run queries asynchronously.</td></tr>
/// </table>
/// <br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace within whose scope the option is set.<br>
/// <dt><i>OptionName</i>
/// <dd>The name of the option (case insensitive), validated against a list of supported options.<br>
/// <dt><i>OptionValue</i>
/// <dd>The value to which to set the option, validated against allowed values for 
/// the specified option.  Omitting this parameter, or specifying "", 
/// causes the specified option to be undefined, resulting in the default behavior 
/// described in the table above.<br>
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Set the option "ConnectTimeout" to 15 in the namespace "MASTER":<br>
/// set status = $SYSTEM.Sharding.SetOption("MASTER", "ConnectTimeout", 15)
/// </ul>
ClassMethod SetOption(MasterNamespace As %String = {$namespace}, OptionName As %String, OptionValue As %Integer = "") As %Status
{
	$$$SSCheckShardingLicense
	$$$SSCheckClusterVersion(MasterNamespace)
	new $namespace
	s $namespace=MasterNamespace
	if '$$validateOptionName^%SYS.SHARDSRV(OptionName) {
		return $$$ERROR($$$SHMInvalidOptionName,OptionName)
	}
	if '$$validateOptionValue^%SYS.SHARDSRV(OptionName,OptionValue) {
		return $$$ERROR($$$SHMInvalidOptionValue,OptionValue,OptionName)
	}
	if '$d($$$SSGlobal) {
		// Since we are creating ^IRIS.SM for the first time here, store our version,
		// so subsequent calls don't mistake this for a prehistoric version and
		// return a version mismatch error.
		s $$$SSGlobal($$$SSProductVersionSubscript)=$system.Version.GetNumber()
		s $$$SSGlobal($$$SSShardingVersionSubscript)=$$$SSShardingVersion
	}
	s OptionName=$zcvt(OptionName,"L")
	if OptionName'="debug"&&(OptionName'="masteripaddress")&&(OptionValue'="") {
		s OptionValue=+OptionValue
	}
	if OptionValue="" {
		k $$$SSGlobal(OptionName)
	}
	else {
		s $$$SSGlobal(OptionName)=OptionValue
	}
	return $$$OK
}

/// Gets the value of a sharding configuration option specified by name, within the scope
/// of a specified master namespace. 
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace within whose scope the option's value is determined.<br>
/// <dt><i>OptionName</i>
/// <dd>The name of the option (case insensitive), validated against a list of supported options.<br>
/// <dt><i>OptionValue</i> (Output)
/// <dd>This parameter is set to the option's value.<br>
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>See <method>SetOption</method> for a table of supported options, the meanings of their values,
/// and the default behavior if they are not set.
/// </ul>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Set the variable connectTimeout to the value of of the option "ConnectTimeout"
/// in the namespace "MASTER":<br>
/// set status = $SYSTEM.Sharding.GetOption("MASTER","ConnectTimeout",connectTimeout)
/// </ul>
ClassMethod GetOption(MasterNamespace As %String = {$namespace}, OptionName As %String, ByRef OptionValue As %Integer) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	new $namespace
	s $namespace=MasterNamespace
	if '$$validateOptionName^%SYS.SHARDSRV(OptionName) {
		return $$$ERROR($$$SHMInvalidOptionName,OptionName)
	}
	s OptionValue=$g($$$SSGlobal($zcvt(OptionName,"L")))
	s:OptionValue="" OptionValue=$$defaultOptionValue^%SYS.SHARDSRV(OptionName)
	return $$$OK
}

/// Activates shards that could not be activated by prior calls to <method>AssignShard</method>.
/// <p>If new data shards are assigned when sharded tables already exist, <method>AssignShard</method>
/// attempts to connect to the newly assigned shards to verify them before they are activated.
/// If this fails (either because the new shards are not reachable, or because they fail verification),
/// <method>AssignShard</method> returns an error indicating that <method>ActivateNewShards</method>
/// must be called to activate the new shards.
/// <p>If this API call returns an error, it can be called again, after correcting the problem reported in
/// the error, until it succeeds.  If there are multiple shards requiring activation, none of them is
/// activated until all of them can be successfully activated.
/// <p>Newly assigned shards are always automatically activated, except in the case where sharded
/// tables already exist and the new shards cannot be reached or cannot be verified.  Therefore,
/// <method>ActivateNewShards</method> never needs to be called unless new shards are assigned while
/// sharded tables already exist.
/// 
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>MasterNamespace</i>
/// <dd>The master namespace whose new shards are to be activated.  Defaults to the current namespace.<br>
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>When new shards have not yet been successfully activated, the master namespace's shard count
/// has not been incremented to include them.  This ensures that all sharded operations can continue
/// executing on activated shards with no problems, without being affected by the existence of shards
/// that have not yet been activated.  When this API call succeeds in activating new shards, it
/// increments the shard count by the number of newly-activated shards, making them available for use
/// in all sharded operations. Existing data stored in other shards is not moved to newly activated shards,
/// but data inserted after they are activated is evenly balanced across all shards including newly activated shards.
/// <li>Shards which have been assigned but not yet activated are listed by <method>ListShards</method>
/// with their shard number in parentheses and followed by an asterisk, for example "(25*)". 
/// </ul>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Activate shards newly assigned to the current namespace:<br>
/// set status = $SYSTEM.Sharding.ActivateNewShards()
/// </ul>
ClassMethod ActivateNewShards(MasterNamespace As %String = {$namespace}) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	return ##class(%BigData.ShardingManager).%ActivateNewShards(MasterNamespace)
}

/// Rebalances existing sharded data across all current shards, including newly assigned ones.  Causes future inserts to 
/// all sharded tables to be balanced across all shards that exist at the time <i>Rebalance</i> is called.<p>
/// Rebalancing, together with the capability to assign new shards, provides
/// elasticity to sharded clusters.<p>
/// 
/// Data is rebalanced at the granularity of "buckets".  For tables with
/// user-defined shard keys, rows of data are assigned to buckets based on
/// a hash of the shard key.  There are always 2048 buckets, and the
/// number of rows per bucket varies depending on the size of a table.
/// For tables with system-assigned shard keys, rows are assigned to buckets
/// based on ranges of rowids.  Each range contains 256,000 rowid values,
/// providing a fixed maximum bucket size, and the number of buckets
/// varies with the size of the table.<p>
/// 
/// Internally, the shard locations of a table's buckets are recorded in a
/// "shard map".  All tables with user-defined shard keys share the same
/// shard map, ensuring that they are always mutually "cosharded" (that
/// is, rows with the same user-defined shard key value will be located in
/// the same shard, for tables with the same number and order of shard key
/// fields).  For tables with system-assigned shard keys, each table has
/// its own shard map (which is shared by any table that is specified to
/// "COSHARD WITH" that table).<p>
/// 
/// Rebalancing moves buckets from shards with more than average number of
/// buckets to shards with less than average, until the bucket counts of
/// all shards differ by at most 1.  Rebalancing modifies the shard maps
/// accordingly, so that internal logic can always find rows in their
/// current locations, and newly inserted data will be stored in the shard
/// to which rebalancing has moved the bucket to which the data belongs.
/// <p>
/// When, for all sharded tables, the buckets counts of all shards differ
/// by no more than one, the cluster is considered to be completely rebalanced.  By
/// default, <method>Rebalance</method> runs until the cluster is completely rebalanced.
/// If the <i>TimeLimit</i> argument is specified to restrict rebalancing
/// to a maintenance window, multiple calls to <method>Rebalance</method> may be required
/// to reach a completely rebalanced state.  Between these calls, the
/// cluster and all sharded data it contains is in a fully usable state,
/// but is not yet taking full advantage of newly-added shards. <p>
/// If any data shards are flagged for pending removal, due to calling <method>DeassignShard</method>
/// or the <class>%SYSTEM.Cluster</class> method <b>Detach</b>, all sharded data is moved from those
/// shards to other shards that are not flagged for pending removal.   In that case, the cluster is
/// not considered to be completely rebalanced until all sharded data has been removed from shards that
/// are flagged for pending removal.  Once the cluster is completely rebalanced, <b>Rebalance</b> completes
/// the process of removing the shards that are flagged for pending removal.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Namespace</i>
/// <dd>A namespace in the current instance, which is a master or shard namespace of the sharded cluster to rebalance. Defaults to the current namespace.<br>
/// <dt><i>TimeLimit</i>
/// <dd>Specifies, in seconds, the time window within which this call should aim to complete (defaults to 0, meaning no 
/// time limit).  No new bucket move is started, whose expected execution time would exceed this time limit (based on 
/// the average execution time for moving previous buckets of the same shard map).   A minimum of <i>MinBuckets</i> is moved, 
/// regardless of the time limit.  A bucket move is an atomic operation which is never interrupted, once started, so total 
/// execution time may exceed the specified time limit, if the last bucket move takes longer than average for buckets of the same shard map. 
/// <dt><i>Report</i>
/// <dd>Returns detailed information about the rebalancing operation, in a subscripted variable, as follows:<p>
/// <li>Report("Completed"): Set to 1 if all sharded tables have been fully rebalanced, or 0 if further rebalancing is 
/// required.
/// <li>Report("Elapsed Seconds"): Elapsed time for executing this call, in seconds.
/// <li>Report("Buckets Moved"): The cumulative total number of buckets moved by this and previous calls, since rebalancing
/// started.
/// <li>Report("Buckets To Move"): The total number of buckets remaining to be moved, for rebalancing of all sharded 
/// tables to be completed.
/// <li>Report("Maps",<i>mapname</i>,"Buckets Moved"): The cumulative number of buckets moved by this and previous 
/// calls, for the shard map identified by <i>mapname</i>, which is the class name of one of the tables which share this 
/// map, or the special map name "||udsk" used for tables with user defined shard keys.
/// <li>Report("Maps",<i>mapname</i>,"Buckets To Move"): The number of buckets remaining to be moved for the shard map 
/// identified by <i>mapname</i>.
/// <li>Report("Maps",<i>mapname</i>,"Average Time"): The average time for moving a bucket of the shard map identified 
/// by <i>mapname</i>, computed cumulatively since rebalancing started.
/// <p>If Rebalance fails, leaving a bucket in an inconsistent, incompletely moved state, Report contains the following 
/// additional information:
/// <li>Report("Incomplete Move"): Map name identifying the shard map for which a move was incomplete.
/// <li>Report("Maps",<i>mapname</i>,"Incomplete Move","Bucket"): The bucket number of the shard map identified by 
/// <i>mapname</i>, which was incompletely moved.
/// <li>Report("Maps",<i>mapname</i>,"Incomplete Move","From Shard"): The shard number from which the bucket was being moved.
/// <li>Report("Maps",<i>mapname</i>,"Incomplete Move","To Shard"): The shard number to which the bucket was being moved.
/// <li>Report("Maps",<i>mapname</i>,"Incomplete Move","Action Needed"): The action needed to correct the situation, which 
/// will be automatically performed at the beginning of the next call to Rebalance.  One of:
/// <dd><li>"Delete New": Delete any data belonging to this bucket from the new location.  A complete copy of this bucket is 
/// guaranteed to still exist at the old location. 
/// <li>"Delete Old": Delete any data belonging to this bucket from the old location.  A complete copy of this bucket is 
/// guaranteed to already exist at the new location.
/// <li>"Update Map": Update the shard map to record this bucket's new location.  The bucket's data is guaranteed to have 
/// already been moved to the new location.
/// </dd></ul></dl>
/// <dt><i>MinBuckets</i>
/// <dd>The minimum number of buckets to move during this call to Rebalance, regardless of the time limit (default 1).  
/// If 0 is specified, no buckets will be moved if the average bucket move time for every shard map is greater than the 
/// specified time limit.
/// </dd>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li><method>Rebalance</method> can be called in any master or shard namespace of
/// a cluster (that is, in the cluster namespace of any cluster node, to use the
/// "node level" terminology used with the <class>%SYSTEM.Cluster</class> API).
/// <li>While rebalancing is in progress, JDBC batch inserts to sharded
/// tables are not permitted, and will return an error if attempted.  All
/// other operations on sharded tables are permitted, including queries,
/// updates, inserts, deletes, creating, altering and dropping tables, as
/// well as assigning new shards.  Performance of some operations may be
/// slower than when rebalancing is not in progress, but all operations
/// will execute correctly.
/// <li>When new shards are assigned, newly inserted data in tables with
/// user-defined shard keys is not stored in the new shards until
/// rebalancing has been performed, because the shard map records all hash
/// buckets as being located on previously-existing shards, until
/// rebalancing moves hash buckets to new shards, logically as well as
/// physically.  For tables with system-assigned shard keys, new inserts
/// are evenly distributed across all shards, new as well as preexisting,
/// whether or not rebalancing has yet been performed.  Rebalancing
/// redistributes the previously existing data of these tables, but does
/// not affect where newly-inserted rows are stored.
/// <li>Rebalancing keeps track of its internal state persistently, so
/// that if it fails for any reason, <method>Rebalance</method> can be called again to
/// resume and complete the rebalancing process.  This includes cases in
/// which <method>Rebalance</method> returns an error, as well as cases where the job in
/// which Rebalance was running has halted, or the IRIS instance in which
/// <method>Rebalance</method> was running has been restarted, while rebalancing was in
/// progress.  After a failure, the cluster remains in "rebalancing in
/// progress" mode until <method>Rebalance</method> is called again and either completes
/// the entire rebalancing process, or reaches the specified
/// <i>TimeLimit</i>.  While in this mode:
/// <dd><li>
/// Queries, inserts, updates, deletes continue to be executed in
/// "rebalancing in progress" mode, guaranteeing that they execute
/// correctly.
/// <li>
/// JDBC batch inserts continue to be prohibited.
/// <li>
/// Inserts, updates, and deletes of data in buckets that have been moved
/// continue to be forwarded to the new bucket locations.  If one or more
/// cluster nodes have been restarted, background daemons manage this
/// transparently.  These daemons automatically terminate once rebalancing
/// is completed.
/// </dd>
/// <li>
/// When, due to <i>TimeLimit</i> being specified,
/// <method>Rebalance</method> completes without error, but without
/// completely rebalancing the cluster, the cluster is not left in
/// "rebalancing in progress" state.  Rather, it is left in a fully
/// useable state that is identical to a completely rebalanced state,
/// except that bucket counts differ between shards by more than 1.  It is
/// guaranteed that for tables that share the same shard map, if a bucket
/// has been moved, the data belonging to that bucket has been moved for
/// all tables sharing the shard map, guaranteeing that cosharded tables
/// remain cosharded at all times.
/// </ul>
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Completely rebalance the cluster to which the current namespace belongs:<br>
/// set status = $SYSTEM.Sharding.Rebalance()
/// <li>Completely rebalance the cluster to which the current namespace belongs, returning a report
/// in the variable <i>report</I>:<br>
/// set status = $SYSTEM.Sharding.Rebalance(,,.report)
/// <li>Rebalance the cluster to which namespace "SHARD1" belongs, moving as many buckets as can be moved within
/// a one hour maintenance window, and returning a report in the variable <i>report</i>:<br>
/// set status = $SYSTEM.Sharding.Rebalance("SHARD1",3600,.report,0)
/// <li>Rebalance the cluster to which namespace "SHARD1" belongs, moving as many buckets as can be moved within
/// a one minute maintenance window, but moving at least one bucket, even if moving that one bucket is expected to take more than 
/// one minute, and returning a report in the variable <i>report</i>:<br>
/// set status = $SYSTEM.Sharding.Rebalance("SHARD1",60,.report,1)
/// </ul>
ClassMethod Rebalance(Namespace As %String = {$namespace}, TimeLimit As %Integer = 0, ByRef Report, MinBuckets As %Integer = 1) As %Status
{
	$$$SSCheckClusterVersion(Namespace)
	kill elapsedTime,bucketsMoved,bucketsToMove
	return:MinBuckets<0 $$$ERROR($$$InvalidArgument)
	s status=$$rebalance^%SYS.SHARDSRV(Namespace,MinBuckets,,TimeLimit,.Report)
	return status
}

/// Reports the progress and status of the current <method>Rebalance</method> operation.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Namespace</i>
/// <dd>A namespace in the current instance, which is a master or shard namespace of the sharded cluster in which <b>Rebalance</b> is running. Defaults to the current namespace.<br>
/// <dt><i>Report</i>
/// <dd>Returns information about <b>Rebalance</b> progress and status, in a subscripted variable, as follows:<p>
/// <li>Report("State"): The overall state of the <b>Rebalance</b> operation.  One of:
/// <dd><li>"Setting Up": <b>Rebalance</b> is preparing to move data.
/// <li>"Moving Data": <b>Rebalance</b> is currently moving data.
/// <li>"Cleaning Up": <b>Rebalance</b> is deleting data from old locations and updating metadata to complete the rebalancing operation.
/// <li>"Timed Out": <b>Rebalance</b> was run with a time limit specified, and has stopped executing after reaching that time limit.
/// <li>"Terminated With Error": <b>Rebalance</b> stopped executing due to an error.  The specific error is reported in Report("Status").
/// <li>"Not Running": <b>Rebalance</b> is not currently running. Either it has not yet started, or has completed with no error, or was never called.
/// </dd></ul>
/// <li>Report("Status"): The success or error status of the <b>Rebalance</b> operation.
/// <li>Report("Tables"): Information about tables being rebalanced or considered for rebalancing, subscripted by table name.   The following is reported for each table:
/// <dd><li>"Buckets Moved": The cumulative total number of buckets of this table moved by this and previous <b>Rebalance</b> calls, since rebalancing started.
/// <li>"Buckets To Move": The total number of buckets remaining to be moved, for rebalancing of this table to be completed.
/// <li>"Operation:": The type of rebalancing operation being performed on this table, one of:
/// <dd><li>"Convert To Sharded": This table is being converted from nonsharded to sharded.
/// <li>"Convert To Nonsharded": This table is being converted from sharded to nonsharded.
/// <li>"Rebalance": This table is not being converted, it is just being rebalanced.  If "Buckets To Move" and "Buckets Moved" both equal 0, this table was considered for rebalancing, but no rebalancing was needed.
/// </dd></ul></dl>
/// </ul>
ClassMethod CheckRebalanceProgress(Namespace As %String = {$namespace}, ByRef Report) As %Status
{
	$$$SSCheckClusterVersion(Namespace)
	s status=$$rbProgress^%SYS.SHARDSRV(Namespace,.Report)
	return status
}

/// Specifies the IP address or DNS name to be used by this InterSystems IRIS instances, when 
/// interconnecting with other instances in a sharded cluster, rather than using the IP address resulting from 
/// resolving this machine's default hostname.
/// <p>This API call does not need to be used in most sharded cluster deployment scenarios.  It is only needed when 
/// neither DNS resolution of the default hostname, nor calling $SYSTEM.TCPDevice.LocalAddr() on an open TCP device, return 
/// an IP address that is usable for interconnecting nodes of a cluster.  (For purposes of this discussion, the default
/// hostname is the name returned by $piece($system,":",1) in an IRIS session).
/// <p>When this API call is needed, it must be called in each instance of a sharded cluster, before any shards are 
/// assigned (in the case of a shard master instance), before any namespace in the current instance is assigned as a
/// shard (in the case of a data shard or query shard instance), or before any sharded operations or other sharding 
/// API calls are made in this instance (in the case of a master app server instance).  The same IP address 
/// or DNS name specified 
/// for a shard instance in this API call should also be passed as the ShardHost argument to 
/// <method>AssignShard</method> when assigning a namespace in the instance as a shard, rather than passing 
/// the machine's default hostname.
/// <p><b>Parameters:</b>
/// <dl>
/// <dt><i>NodeIPAddress</i>
/// <dd>The IP address or DNS name to be used by this InterSystems IRIS instance, when 
/// interconnecting with other instances in a sharded cluster.
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>A user must have administrative privileges in order to execute this API call.
/// <li>Recommended practice: Specify an IP address, in scenarios where the machine's IP address will remain constant, but there is no
/// hostname or DNS name available that resolves to this address.
/// Specify a DNS name, in scenarios in which the machine's IP address may change regularly, but the default hostname
/// cannot be counted on to resolve to the correct current IP address needed for interconnecting with other cluster
/// nodes.  It may be necessary to define a DNS name / IP address mapping outside of InterSystems IRIS 
/// (for example, in /etc/hosts on Unix systems), and update that mapping as the machine's IP address changes, but
/// this avoids needing to reconfigure the cluster when IP addresses change.
/// <li>This API call affects an entire InterSystems IRIS instance. If this instance participates in more than one
/// sharded cluster (e.g. contains more than one master namespace, or shards belonging to more than
/// one master namespace), this call specifies the IP address used for this instance in
/// all of the clusters in which this instance participates.
/// <li>This API call provides similar functionality to that provided by the setting the deprecated sharding option 
/// "MasterIPAddress", but this API call works in a wider range of scenarios.  Sharded clusters that are already working
/// using "MasterIPAddress" do not need to be modified, but it is recommended that SetNodeIPAddress be used
/// when configuring new sharded clusters.
/// </ul></dl>
/// <p><b>Example</b>:
/// <ul>
/// <li>Set this instance's IP address to "10.0.0.76":<br>
/// set status = $SYSTEM.Sharding.SetNodeIPAddress("10.0.0.76")
/// <li>Set this instance's DNS name to "mydnsname":<br>
/// set status = $SYSTEM.Sharding.SetNodeIPAddress("mydnsname")
/// </ul>
ClassMethod SetNodeIPAddress(NodeIPAddress As %String) As %Status
{
	return $$setNodeIPAddress^%SYS.SHARDSRV(NodeIPAddress)
}

ClassMethod Reset(Namespace As %String = "") As %Status [ Internal ]
{
	return $$resetCluster^%SYS.SHARDSRV(Namespace)
}

ClassMethod SetShardBrokeredHost(Namespace As %String = "", ShardNumber As %Integer = 0, BrokeredHost As %String = "", Backup As %Boolean = 0) As %Status
{
	s:Namespace="" Namespace=$namespace
	return ##class(%BigData.ShardingManager).%SetShardBrokeredHost(Namespace,ShardNumber,BrokeredHost,Backup)
}

ClassMethod AddDatabasesToMirrors(MasterNamespace As %String = {$namespace}) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	return $$addDatabasesToMirrors^%SYS.SHARDSRV(MasterNamespace)
}

ClassMethod RemoveMirroring(MasterNamespace As %String = {$namespace}, Verbose As %Boolean = 1) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	if +$g($$$SSExtendedGlobal(MasterNamespace)($$$SSRemoveMirroring1CompletedSubscript)) {
		return $$removeMirroring2^%SYS.SHARDSRV(MasterNamespace,Verbose)
	}
	else {
		return $$removeMirroring1^%SYS.SHARDSRV(MasterNamespace,Verbose)
	}
}

ClassMethod PurgeShard(MasterNamespace As %String = {$namespace}, ShardHost As %String, ShardPort As %Integer, ShardNamespace As %String, ShardNumber As %Integer) As %Status
{
	$$$SSCheckClusterVersion(MasterNamespace)
	if ($g(ShardHost)="")||($g(ShardPort)="")||($g(ShardNamespace)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardingManager).%PurgeShard(MasterNamespace,ShardHost,ShardPort,ShardNamespace,ShardNumber)
}

ClassMethod ClusterIsNodeLevel(ClusterNamespace As %String = {$namespace}) As %Boolean
{
	new $namespace
	s:$namespace'=ClusterNamespace $namespace=ClusterNamespace
	return (+$g($$$SSGlobal($$$SSSimpleSubscript))=1)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Returns information about a specified federated table.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ShardNamespace</i>
/// <dd>A shard namespace in the current InterSystems IRIS instance (which must belong to a sharded cluster).
///  Defaults to the current namespace.<br>
/// <dt><i>FederatedTableName</i>
/// <dd>The name of the federated table.  Must be a valid table name.<br>
/// <dt><i>Info</i>
/// <dd>Output parameter which returns information about the specified federated table as an array subscripted by
/// shard number.  For each shard number, the format is:
/// <dd><code>Info(shardNumber) = $lb(sourceNamespace, sourceTableName, columnList)</code><br>
/// <dd>where <i>columnList</i> is in the format:
/// <<dd><code>$lb( $lb(sourceColumnName1, federatedColumnName1), ...)</code> <br>
/// <li>If no source table is connected to the specified federated table in a given shard, that shard's entry is:
/// <dd><code>Info(shardNumber) = ""</code><br>
/// </dd>
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>Call <method>ListShards</method> or <method>GetConfig</method> to determine the hostname, port, or namespace corresponding to a shard number.
/// </dd>
/// </dd></dd></ul></dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Get information about a federated table called "Sample.Person" in the current shard namespace, to be returned in the variable <i>personInfo</i>:<br>
/// <code>set status = $SYSTEM.Sharding.GetFederatedTableInfo(,"Sample.Person",.personInfo)</code>
ClassMethod GetFederatedTableInfo(ShardNamespace As %String = {$namespace}, FederatedTableName As %String = "", Output Info As %List) As %Status
{
	if $g(FederatedTableName)="" {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardedSQL).%GetFederatedTableInfo(ShardNamespace,FederatedTableName,.Info)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Creates a read-only federated table, based on a specified source table.
/// <p>If the specified federated table already exists, this method re-creates it, based on the current definition 
/// of the source table.
/// <p>The federated table is visible in any shard namespace of the sharded cluster to which the specified <i>ShardNamespace</i>
/// belongs. The list of columns determined by this method, either based on the list of columns of the specified
/// source table, or customized with the optional <i>ColumnList</i> argument, becomes the list of columns
/// for the overall federated table.   Additional source tables can be attached to this federated table, on any instance of this sharded cluster,
/// by calling <method>ConnectFederatedTable</method> in that instance, specifying a <i>ShardNamespace</i> and 
/// <i>SourceNamespace</i> on that instance.  Queries of a federated table span all currently-connected source tables.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ShardNamespace</i>
/// <dd>A shard namespace in the current InterSystems IRIS instance (which must belong to a sharded cluster).
/// Must be on same instance as <i>SourceNamespace</i>. The specified namespace must be a data shard, not a
/// query shard.  Defaults to the current namespace.<br>
/// <dt><i>FederatedTableName</i>
/// <dd>The name of the federated table to be created.  Must be a valid table name.<br>
/// <dt><i>SourceNamespace</i>
/// <dd>The namespace containing the source table.   Must be on same instance as <i>ShardNamespace</i>.
/// <dt><i>SourceTableName</i>
/// <dd>The name of the source table.<br>
/// <dt><i>ColumnList</i>
/// <dd>Optionally specifies a customized set of columns for the federated table. <br>Format:
/// <code>$lb( $lb(sourceColumnName1 [, federatedColumnName1 ] ), ...)</code> <br>
/// <li>If <i>ColummList</i> is non-empty, the federated table will have one column for each entry in the list.
/// <li>If federatedColumnNameN is not provided, sourceColumnNameN is used.
/// <li>If any sourceColumnNameN does not exist in the source table, this method returns an error.
/// <li>If <i>ColumnList</i> is not provided, the federated table's set of columns will match the source table's set
/// of columns exactly.
/// </dd>
/// <br>
/// <dt><i>Force</i>
/// <dd>Force the class of the specified source table, and any classes on which it depends, to be projected
/// as proxies in the specified <i>ShardNamespace</i>, even if proxies for those classes already exist.   
/// If <i>Force</i>=0 (the default), new proxies are only created for classes whose proxies do not already exist, which
/// can save significant time when creating multiple federated tables based on a source schema containing many 
/// interdependent classes.
/// Specifying <i>Force</i>=1 ensures that proxies are up-to-date with the latest versions of source classes.
/// <dt><i>Verbose</i>
/// <dd>If <i>Verbose</i>=1 (the default), report each proxy class that is created and compiled, to the output device.
/// If <i>Verbose</i>=0, do not write any progess information.
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>It is permitted for the source table to reside in a read-only database.
/// </dd>
/// <li>If there are changes to the definition of source table, or of classes on which it depends, this method, or <method>ConnectFederatedTable</method>, must be
/// called to re-create proxy classes to match the current source definitions.
/// </dd></dd></ul></dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Create a federated table called "Sample.Person" in the current shard namespace, whose list of columns exactly matches the 
/// source table Sample.Person from the <i>SourceNamespace</i> "Samples":<br>
/// <code>set status = $SYSTEM.Sharding.CreateFederatedTable(,"Sample.Person","Samples","Sample.Person")</code>
/// <li>Create a federated table called "Myschema.Person" in the shard namespace "IRISCLUSTER", with a customized column list
/// based on the source table Sample.Person in the <i>SourceNamespace</i> "Samples":<br>
/// <code>set status = $SYSTEM.Sharding.CreateFederatedTable(,"Myschema.Person","Samples","Sample.Person",$lb($lb("name"),$lb("home_city","homecity"),$lb("age")))</code>
/// </ul>
ClassMethod CreateFederatedTable(ShardNamespace As %String = {$namespace}, FederatedTableName As %String = "", SourceNamespace As %String, SourceTableName As %String, ColumnList As %List = "", Force As %Boolean = 0, Verbose As %Boolean = 1) As %Status
{
	if ($g(FederatedTableName)="")||($g(SourceNamespace)="")||($g(SourceTableName)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardedSQL).%CreateFederatedTable(ShardNamespace,1,FederatedTableName,SourceNamespace,SourceTableName,ColumnList,Force,Verbose)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Connect an additional source table to a read-only federated table, which has been created by a previous call
/// to <method>CreateFederatedTable</method>.
/// <p>If a source table has already been connected to the specified <i>FederatedTableName</i> in the specified <i>ShardNamespace</i>,
/// it is replaced by the source table specified by <i>SourceTableName</i>.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ShardNamespace</i>
/// <dd>A shard namespace in the current InterSystems IRIS instance (which must belong to a sharded cluster).
/// Must be on same instance as <i>SourceNamespace</i>. The specified namespace must be a data shard, not a
/// query shard. Defaults to the current namespace.<br>
/// <dt><i>FederatedTableName</i>
/// <dd>The name of the federated table to which the specified source table will be connected.  
/// <dt><i>SourceNamespace</i>
/// <dd>The namespace containing the source table.   Must be on same instance as <i>ShardNamespace</i>.
/// <dt><i>SourceTableName</i>
/// <dd>The name of the source table.<br>
/// <dt><i>ColumnList</i>
/// <dd>Optionally specifies a customized mapping of columns from the source table to the federated table. <br>Format:
/// <code>$lb( $lb(sourceColumnName1 [, federatedColumnName1 ] ), ...)</code> <br>
/// <li>If federatedColumnNameN is not provided, sourceColumnNameN is used.
/// <li>If any federatedColumnNameN does not exist in the federated table, this method returns an error.
/// <li>If any sourceColumnNameN does not exist in source table, this method returns an error.
/// <li> If <i>ColumnList</i> is not provided at all, all columns in the federated table for which a column of the
/// same name exists in the source table will be mapped.
/// <li>For any column in the federated table for which no corresponding column in the source is specified 
/// (either explicitly or because <i>ColumnList</i>  is not provided), rows of this source table will be padded 
/// with NULL values when queried.
/// </dd>
/// <br>
/// <dt><i>Force</i>
/// <dd>Force the class of the specified source table, and any classes on which it depends, to be projected
/// as proxies in the specified <i>ShardNamespace</i>, even if proxies for those classes already exist.   
/// If <i>Force</i>=0 (the default), new proxies are only created for classes whose proxies do not already exist, which
/// can save significant time when creating multiple federated tables based on a source schema containing many 
/// interdependent classes.
/// Specifying <i>Force</i>=1 ensures that proxies are up-to-date with the latest versions of source classes.
/// <dt><i>Verbose</i>
/// <dd>If <i>Verbose</i>=1 (the default), report each proxy class that is created and compiled, to the output device.
/// If <i>Verbose</i>=0, do not write any progess information.
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>It is permitted for the source table to reside in a read-only database.
/// </dd>
/// <li>If there are changes to the definition of the source table, or of classes on which it depends, this method, or <method>CreateFederatedTable</method>, must be
/// called to re-create proxy classes to match the current source definitions.
/// </dd>
/// </dl></dd></ul></dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Connect the source table Sample.Person, from the <i>SourceNamespace</i> "Samples", to the federated table "Sample.Person"
/// in the current shard namespace:<br>
/// <code>set status = $SYSTEM.Sharding.ConnectFederatedTable(,"Sample.Person","Samples","Sample.Person")</code>
/// <li>Connect the source table Sample.Person, from the <i>SourceNamespace</i> "Samples", to the federated table 
/// "Myschema.Person" in the shard namespace "IRISCLUSTER", with a customized column list:<br>
/// <code>set status = $SYSTEM.Sharding.ConnectFederatedTable(,"Myschema.Person","Samples","Sample.Person",$lb($lb("name"),$lb("home_city","homecity"),$lb("age")))</code>
/// </ul>
ClassMethod ConnectFederatedTable(ShardNamespace As %String = {$namespace}, FederatedTableName As %String = "", SourceNamespace As %String, SourceTableName As %String, ColumnList As %List = "", Force As %Boolean = 0, Verbose As %Boolean = 1) As %Status
{
	if ($g(FederatedTableName)="")||($g(SourceNamespace)="")||($g(SourceTableName)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardedSQL).%CreateFederatedTable(ShardNamespace,0,FederatedTableName,SourceNamespace,SourceTableName,ColumnList,Force,Verbose)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Drop a read-only federated table, which has been created by a previous call
/// to <method>CreateFederatedTable</method>.
/// <p>This method does not delete any data, and has no effect on any of the source tables that are connected to
/// this federated table.  It only drops the federated table's definition, and drops any proxy classes that were
/// projected for this federated table in any shard namespace of this sharded cluster, unless those proxy classes are
/// still needed for another federated table.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ShardNamespace</i>
/// <dd>A shard namespace in the current InterSystems IRIS instance (which must belong to a sharded cluster). 
/// Defaults to the current namespace.
/// <dt><i>FederatedTableName</i>
/// <dd>The name of the federated table to be dropped.  
/// </dd>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Drop the federated table Myschema.Person, in the current shard namespace:<br>
/// <code>set status = $SYSTEM.Sharding.DropFederatedTable(,"Myschema.Person")</code>
ClassMethod DropFederatedTable(ShardNamespace As %String = {$namespace}, FederatedTableName As %String = "") As %Status
{
	if ($g(FederatedTableName)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardedSQL).%DropFederatedTable(ShardNamespace,FederatedTableName)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Disconnect this shard from a read-only federated table, which has been created by a previous call
/// to <method>CreateFederatedTable</method>.
/// <p>This method does not delete any data, and has no effect on any of the source tables that are connected to
/// this federated table.  It only disconnects any source table that was connected to this federated table
/// on this shard, by a previous call to <method>CreateFederatedTable</method> or <method>ConnectFederatedTable</method>, 
/// and drops any proxy classes that were
/// projected for this federated table in this shard namespace, unless those proxy classes are
/// still needed for another federated table.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ShardNamespace</i>
/// <dd>A shard namespace in the current InterSystems IRIS instance (which must belong to a sharded cluster). The specified namespace must be a data shard, not a
/// query shard. Defaults to the current namespace.
/// <dt><i>FederatedTableName</i>
/// <dd>The name of the federated table from which to disconnect.  
/// </dd>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Disconnect from the federated table Myschema.Person, in the current shard namespace:<br>
/// <code>set status = $SYSTEM.Sharding.DisconnectFederatedTable(,"Myschema.Person")</code>
ClassMethod DisconnectFederatedTable(ShardNamespace As %String = {$namespace}, FederatedTableName As %String = "") As %Status
{
	if ($g(FederatedTableName)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardedSQL).%DisconnectFederatedTable(ShardNamespace,FederatedTableName)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Connect a previously disconnected shard, specified by <i>ShardHost</i>, <i>ShardPort</i>, and <i>ShardNamespace</i>, to the sharded cluster specified by <i>ClusterNamespace</i>.
/// The specified shard must previously have been assigned using <method>AssignShard</method>. If the
/// specified shard was not previously disconnected (by calling <method>DisconnectShard</method>), this class method has no effect.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ClusterNamespace</i>
/// <dd>A shard or master namespace in the current InterSystems IRIS instance, used to specify the sharded cluster to which
/// the namespace belongs. Defaults to the current namespace.
/// <dt><i>ShardHost</i>
/// <dd>The machine hosting the shard namespace, specified by hostname or IP address.<br>
/// <dt><i>ShardPort</i>
/// <dd>The default port (Super Server port) of the InterSystems IRIS instance hosting the shard namespace.<br>
/// <dt><i>ShardNamespace</i>
/// <dd>The namespace of the shard being connected.<br>
/// </dd>
ClassMethod ConnectShard(ClusterNamespace As %String = {$namespace}, ShardHost As %String, ShardPort As %Integer, ShardNamespace As %String) As %Status
{
	// JMM1256 - New classmethod
	if ($g(ShardHost)="")||($g(ShardPort)="")||($g(ShardNamespace)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardingManager).%ConnectOrDisconnectShard(ClusterNamespace,ShardHost,ShardPort,ShardNamespace,2)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Disconnect a shard, specified by <i>ShardHost</i>, <i>ShardPort</i>, and <i>ShardNamespace</i>, from the sharded cluster specified by <i>ClusterNamespace</i>.
/// A disconnected shard does not participate in queries of federated tables.  Therefore, an
/// inaccessible shard can be disconnected to prevent it from causing federated queries to fail, but the queries won't include results from the
/// disconnected shard.
/// <p>A shard can only be disconnected from a designated federated overlay cluster. 
/// A sharded cluster is designated as a federated overlay cluster by setting the option <i>FederatedOverlay</i> to 1 using <method>SetOption</method>
/// after at least one shard has been assigned (by calling <method>AssignShard</method>), and before <method>VerifyShards</method> is called. 
/// <p>To reconnect a shard after it has been disconnected, call <method>ConnectShard</method>. 
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ClusterNamespace</i>
/// <dd>A shard or master namespace in the current InterSystems IRIS instance, used to specify the sharded cluster to which
/// the namespace belongs. Defaults to the current namespace.
/// <dt><i>ShardHost</i>
/// <dd>The machine hosting the shard namespace, specified by hostname or IP address.<br>
/// <dt><i>ShardPort</i>
/// <dd>The default port (Super Server port) of the InterSystems IRIS instance hosting the shard namespace.<br>
/// <dt><i>ShardNamespace</i>
/// <dd>The namespace of the shard being disconnected.<br>
/// </dd>
ClassMethod DisconnectShard(ClusterNamespace As %String = {$namespace}, ShardHost As %String, ShardPort As %Integer, ShardNamespace As %String) As %Status
{
	
	// JMM1256 - New classmethod
	if ($g(ShardHost)="")||($g(ShardPort)="")||($g(ShardNamespace)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardingManager).%ConnectOrDisconnectShard(ClusterNamespace,ShardHost,ShardPort,ShardNamespace,1)
}

/// <i>Experimental Feature -- InterSystems reserves the right to make backwards-incompatible changes to this API in future releases</i><p>
/// Determine whether a shard, specified by <i>ShardHost</i>, <i>ShardPort</i>, and <i>ShardNamespace</i>, is currently connected to the sharded cluster specified by <i>ClusterNamespace</i>.
/// The specified shard must previously have been assigned using <method>AssignShard</method>. Returns 1 (if connected)
/// or 0 (if disconnected) in by-reference argument IsConnected.  A shard that has been assigned to a cluster is connected unless
/// it has been disconnected by calling <method>DisconnectShard</method>.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>ClusterNamespace</i>
/// <dd>A shard or master namespace in the current InterSystems IRIS instance, used to specify the sharded cluster to which
/// the namespace belongs. Defaults to the current namespace.
/// <dt><i>ShardHost</i>
/// <dd>The machine hosting the shard namespace, specified by hostname or IP address.<br>
/// <dt><i>ShardPort</i>
/// <dd>The default port (Super Server port) of the InterSystems IRIS instance hosting the shard namespace.<br>
/// <dt><i>ShardNamespace</i>
/// <dd>The namespace of the shard being connected.<br>
/// <dt><i>IsConnected</i>
/// <dd>Returns, by reference, 1 if the shard is connected, or 0 if it is disconnected.
/// </dd>
ClassMethod ShardIsConnected(ClusterNamespace As %String = {$namespace}, ShardHost As %String, ShardPort As %Integer, ShardNamespace As %String, ByRef IsConnected As %Boolean) As %Status
{
	// JMM1256 - New classmethod
	if ($g(ShardHost)="")||($g(ShardPort)="")||($g(ShardNamespace)="") {
		return $$$ERROR($$$InvalidArgument)
	}
	return ##class(%BigData.ShardingManager).%ConnectOrDisconnectShard(ClusterNamespace,ShardHost,ShardPort,ShardNamespace,0,.IsConnected)
}

}
