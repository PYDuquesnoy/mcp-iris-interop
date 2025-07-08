/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%BigData.ShardingManager, %occErrors)

/// This class provides an API for node-level configuration of sharded clusters.
/// <p>You can use it via the special $SYSTEM object, for example:</p>
/// <pre>set status = $SYSTEM.Cluster.Initialize()</pre>
/// <h2>API Usage</h2>
/// <p>Call <method>Initialize</method> to set up an InterSystems IRIS instance as the first node of a new nonmirrored sharded cluster (that is, 
/// a sharded cluster in which all data nodes are nonmirrored).</p>
/// <p>Call <method>InitializeMirrored</method> to set up an InterSystems IRIS instance as the first node of a new mirrored sharded cluster (that is,
/// a sharded cluster in which all data nodes are mirrored).</p>
/// <p>Call <method>AttachAsDataNode</method> to add an instance to a cluster as a nonmirrored data node.</p>
/// <p>Call <method>AttachAsMirroredNode</method> to add an instance to a cluster as a mirrored data node.</p>
/// <p>Call <method>AttachAsComputeNode</method> to add an instance to a cluster as a compute node.</p>
/// <p>Call <method>Detach</method> to detach an instance from a cluster.</p>
/// <p>Call <method>ListNodes</method> to print a list of a cluster's nodes.</p>
/// <p>Call <method>GetMetadata</method> to retrieve an overview of a cluster's metadata.</p>
/// <p>Call <method>ClusterNamespace</method> to get the name of the cluster namespace for the current instance.</p>
/// <h2>Terminology</h2>
/// <dl>
/// <dt><i>Sharded Cluster</i></dt>
/// <dd>An interconnected set of nodes which provides horizonal scalability of 
///  users and data.</dd>
/// <dt><i>Node</i></dt>
/// <dd>An InterSystems IRIS instance that participates in a sharded cluster.
///  Nodes are of two types, "data" and "compute", but all nodes can be
///  used interchangeably as application servers, providing transparent 
///  access to all data in the cluster. Data nodes can be mirrored or nonmirrored. 
/// Compute nodes are always non-mirrored.</dd>
/// <dt><i>Data Node</i></dt>
/// <dd>A node that stores a partition (shard) of sharded data locally.</dd>
/// <dt><i>Compute Node</i></dt>
/// <dd>A node that does not store sharded data locally, but provides compute access 
///  to the sharded data on a corresponding data node, via global mapping.</dd>
/// <dt><i>Cluster URL</i></dt>
/// <dd>The address of a node, specified in the format "IRIS://<i>host</i>:<i>port</i>/<i>cluster-namespace</i>".</dd>
/// <dt><i>Cluster Namespace</i></dt>
/// <dd> A namespace that exists, with the same name, on every node of a sharded
///  cluster, providing transparent access to all sharded and nonsharded data, 
///  and all code, on the cluster.</dd>
/// <dt><i>Master Namespace</i></dt>
/// <dd>A namespace that exists only on node 1 of a sharded cluster.  Metadata
///  and nonsharded data stored in its globals databases, and code
///  stored in its routines database, are accessible in the cluster namespace
///  on every node of the cluster, via database mapping.</dd>
/// <dt><i>Shard Database</i></dt>
/// <dd>A database on each data node that stores a partition (shard) of sharded
///  data. A shard database is not the default database of any namespace,
///  but globals stored in it are visible within the cluster namespace on the
///  same data node, or any associated compute node, via global mapping.</dd>
/// </dl>
/// <h3>Architecture of a Sharded Cluster</h3>
/// <p>Sharded clusters configured using methods of this class have the following
/// architecture:</p>
/// <ul>
/// <li>Each node consists of a separate InterSystems IRIS instance on a
///   separate machine, and participates in only one sharded cluster.</li>
/// <li>Every node has a cluster namespace, which all have the same name on
///   every instance of the cluster ("IRISCLUSTER", by default).</li>
/// <li>A cluster has one or more data nodes, each of which has a shard database
///   which stores one partition (shard) of the cluster's sharded data.
///   Adding data nodes increases the degree of partitioning (number of
///   shards) of sharded data.</li>
/// <li>A cluster is either mirrored or nonmirrored. In a mirrored cluster, all
///   data nodes are mirrored. In a nonmirrored cluster, all data nodes are nonmirrored.</li>
/// <li>A cluster has zero or more compute nodes. These do not store any data,
///   but have mapped access to the sharded data of an associated data node.
///   Zero or more compute nodes can be associated with each data node, and
///   are transparently balanced across data nodes as more compute nodes are
///   added.  Adding compute nodes increases the computing bandwidth for 
///   executing sharded queries.</li>
/// <li>All nonsharded data, and all code, is stored in the globals and routines
///   databases, respectively, of the master namespace on the first node of
///   the cluster, and is transparently accessible in the cluster namespace on
///   every node, via database mapping.  This master namespace, which exists
///   only on the first node, is largely transparent to users, as all user
///   data access can (and should) be done in the cluster namespaces.
///   <p>There is one special case where the master namespace should be used
///     directly: Any globals, package, or routine mappings that should be
///     visible in the cluster namespace on every node should be 
///     defined by users in the master namespace, from which they are 
///     automatically propagated to the cluster namespaces.  Mappings defined
///     by users in a cluster namespace are not propagated, and are only visible
///     in the cluster namespace of the node on which they are defined.</p></li>
/// <li>All sharded data is transparently accessible via SQL in the cluster 
///   namespace of every node.  The underlying globals of each partition of
///   sharded data are only transparently accessible on the data node where that 
///   partition is stored, or on any compute nodes associated with that data 
///   node (although they can be accessed from any node via extended global
///   references).</li>
/// <li> Every node plays a dual role, as an application server providing
///   transparent access to all data and code, and as a shard server which
///   locally executes those portions of sharded queries and updates that
///   access sharded data stored on that node (in the case of a data node),
///   or mapped to that node (in the case of a compute node).  User connections
///   can be load balanced across all nodes, so adding nodes of either type
///   increases the computing bandwidth for user applications.</li>
/// </ul>
/// <h3 id="Prerequisites">Prequisites for Using This API</h3>
/// <ul>
/// <li>Machines must be provisioned and must be mutually accessible via TCP/IP.</li>
/// <li>InterSystems IRIS instances must be installed, with sharding-enabled
///   licenses.</li>
/// <li>InterSystems IRIS instances must have the ECP configuration parameters
///   MaxServers and MaxServerConn set to values at least as great as the
///   anticipated number of nodes in the sharded cluster.  Note that if these
///   values are changed after installation, the instances must be restarted
///   for the new values to take effect.</li>
/// </ul>
Class %SYSTEM.Cluster Extends %SYSTEM.Help
{

/// Sets up the current InterSystems IRIS instance as the first data node of a new cluster.
/// This method automatically and transparently performs all steps needed
/// to enable this instance as the first node of a cluster (subject to
/// these <a href="#Prerequisites">prerequisites</a>), including:
/// <ul>
/// <li>Enables the ECP and sharding services, and sets these
///   services' lists of allowed connections, if specified via the
///   pAllowedConnections argument.</li>
/// <li>Creates the cluster and master namespaces and their databases if they
///   don't already exist.</li>
/// <li>Creates all necessary mappings from the cluster namespace to the
///   globals and routines databases of the master namespace, and
///   to the shard database.</li>
/// </ul>
/// <p>
/// This method returns an error in any of the following cases:
/// <ul>
/// <li>The current InterSystems IRIS instance is already a node of a sharded cluster.</li>
/// <li>The current instance is a mirror member.</li>
/// <li>The specified cluster namespace already exists, and its globals database is mirrored.</li>
/// </ul>
/// <p><b>Parameters:</b></p>
/// <dl>
/// <dt><i>pClusterNamespace</i></dt>
/// <dd>Cluster namespace, visible on all nodes of this cluster, providing access to both sharded and nonsharded data.
///  If specified namespace does not exist, it is created.  Default name: IRISCLUSTER. </dd>
/// <dt><i>pMasterNamespace</i></dt>
/// <dd>Master namespace for this cluster.  
///  If specified namespace does not exist, it is created.  Default name: IRISDM. </dd>
/// <dt><i>pAllowedConnections</i></dt>
/// <dd>List of hosts allowed to participate in this cluster, specified 
///  as a semi-colon-separated list of IP addresses or hostnames.  
///  Default: No restriction of which hosts can participate.  </dd>
/// <dt><i>pHostIPAddress</i></dt>
/// <dd>IP address other nodes of this cluster should use to connect to this node.  Specify a value for
///  for this parameter if the default hostname known to InterSystems IRIS does not resolve to an appropriate address, or no hostname is available.
///  Default: Default hostname will be used for inter-node connections. </dd>
/// </dl>
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.</dd>
/// </dl>
/// <p><b>Notes:</b></p>
/// <ul>
/// <li>If either the cluster namespace or the master namespace already exists, the
/// existing namespace is used.
/// If one of them exists and the other doesn't, the globals database
/// for the one that doesn't exist is created using all of the same configuration
/// settings as the globals database of the namespace that already exists 
/// (other than directory path).  
/// If neither namespace exists, databases for both are created using default 
/// settings.</li>
/// <li>If neither namespace exists, the namespaces are created without enabling
/// interoperability.  If one namespace exists, the other namespace is created 
/// with interoperability enabled or not, according to whether it is enabled
/// in the existing namespace.</li>
/// <li>If the cluster namespace exists, its globals database becomes the shard 
/// database for node 1.  
/// The globals database of the master namespace is used to store all nonsharded
/// data for the cluster, and its routines database is use to store all code
/// for the cluster.</li>
/// </ul>
ClassMethod Initialize(pClusterNamespace As %String = "IRISCLUSTER", pMasterNamespace As %String = "IRISDM", pAllowedConnections As %String = "", pHostIPAddress As %String = "") As %Status
{
	return:$system.Mirror.IsMember() $$$ERROR($$$SHMInstanceCannotBeMirrored,"$SYSTEM.Cluster.Initialize()")
	return ..Init(0,pClusterNamespace,pMasterNamespace,pAllowedConnections,pHostIPAddress)
}

/// Sets up the current InterSystems IRIS instance as the first data node of a new mirrored cluster.
/// This method automatically and transparently performs all steps needed
/// to enable this instance as the first node of a mirrored cluster (subject to
/// these <a href="#Prerequisites">prerequisites</a>), including:
/// <ul>
/// <li>Enables the ECP and sharding services, and sets these
///   services' lists of allowed connections, if specified via the
///   pAllowedConnections argument.</li>
/// <li>If the current instance is not already the primary failover member of a mirror,
///   creates a new mirror set, and configures the current instance as its first
///   failover member.</li>
/// <li>Creates the cluster and master namespaces and their databases if they
///   don't already exist.</li>
/// <li>Creates all necessary mappings from the cluster namespace to the
///   globals and routines databases of the master namespace, and
///   to the shard database.</li>
/// </ul>
/// <p>
/// This method returns an error in any of the following cases:</p>
/// <ul>
/// <li>The current InterSystems IRIS instance is already a node of a sharded cluster.</li>
/// <li>The current instance is already a mirror member, but is not currently the
///  primary failover member.</li>
/// <li>The specified cluster namespace or master namespace already exists, but its globals
///  database is not mirrored.</li>
/// </ul>
/// <p><b>Parameters:</b></p>
/// <dl>
/// <dt><i>pClusterNamespace</i></dt>
/// <dd>Cluster namespace, visible on all nodes of this cluster, providing access to both sharded and nonsharded data.
///  If specified namespace does not exist, it is created.  Default name: IRISCLUSTER.</dd>
/// <dt><i>pMasterNamespace</i></dt>
/// <dd>Master namespace for this cluster.  
///  If specified namespace does not exist, it is created.  Default name: IRISDM.</dd>
/// <dt><i>pAllowedConnections</i></dt>
/// <dd>List of hosts allowed to participate in this cluster, specified 
///  as a semi-colon-separated list of IP addresses or hostnames.  
///  Default: No restriction of which hosts can participate. </dd>
/// <dt><i>pHostIPAddress</i></dt>
/// <dd>IP address other nodes of this cluster should use to connect to this node.  Specify a value for
///  for this parameter if the default hostname known to InterSystems IRIS does not resolve to an appropriate address, or no hostname is available.
///  Default: Default hostname will be used for inter-node connections. </dd>
/// <dt><i>pArbiterIP</i></dt>
/// <dd>Arbiter's hostname or IP address. Specify a non-null value to configure this mirror set to use an arbiter.</dd>
/// <dt><i>pArbiterPort</i></dt>
/// <dd>Arbiter's port. Specify a non-zero value to configure this mirror to use an arbiter.</dd>
/// <dt><i>pSSLDirectory</i></dt>
/// <dd>SSL/TLS keys directory. Specify a non-null value to configure this mirror to use SSL/TLS. Directory is expected to
/// contain three files named "CAFile.pem", "CertificateFile.pem, and "PrivateKeyFile.pem".</dd>
/// <dt><i>pMirrorName</i></dt>
/// <dd>Name of mirror set to create. Default: IRISMIRROR1.</dd>
/// <dt><i>pMemberName</i></dt>
/// <dd>Name by which this instance is known to the mirror. Default: IRISMIRROR1A.</dd>
/// </dl>
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.</dd>
/// </dl>
/// <p><b>Notes:</b></p>
/// <ul>
/// <li>If the current instance is already a mirror member, the mirror configuration parameters (pArbiterIP, 
/// pArbiterPort, pSSLDirectory, pMirrorName, and pMemberName) are ignored, and the mirror 
/// configuration is not modified.</li>
/// <li>If either the cluster namespace or the master namespace already exists, the
/// existing namespace is used.
/// If one of them exists and the other doesn't, the globals database
/// for the one that doesn't exist is created using all of the same configuration
/// settings as the globals database of the namespace that already exists 
/// (other than directory path).  
/// If neither namespace exists, databases for both are created using default 
/// settings.</li>
/// <li>If neither namespace exists, the namespaces are created without enabling
/// interoperability.  If one namespace exists, the other namespace is created 
/// with interoperability enabled or not, according to whether it is enabled
/// in the existing namespace.</li>
/// <li>If the cluster namespace exists, its globals database becomes the shard 
/// database for node 1.  
/// The globals database of the master namespace is used to store all nonsharded
/// data for the cluster, and its routines database is use to store all code
/// for the cluster.</li>
/// </ul>
ClassMethod InitializeMirrored(pClusterNamespace As %String = "IRISCLUSTER", pMasterNamespace As %String = "IRISDM", pAllowedConnections As %String = "", pHostIPAddress As %String = "", pArbiterIP As %String = "", pArbiterPort As %Integer = 0, pSSLDirectory As %String = "", pMirrorName As %String = "IRISMIRROR1", pMemberName As %String = "IRISMIRROR1A") As %Status
{
	if (pArbiterIP'=""&&(pArbiterPort=0))||(pArbiterIP=""&&(pArbiterPort'=0)) {
		return $$$ERROR($$$SHMIncompleteArbiterAddress)
	}
	return ..Init(1,pClusterNamespace,pMasterNamespace,pAllowedConnections,pHostIPAddress,
	 				pArbiterIP,pArbiterPort,pSSLDirectory,pMirrorName,pMemberName)
}

ClassMethod Init(pMirrored As %Boolean, pClusterNamespace As %String = "IRISCLUSTER", pMasterNamespace As %String = "IRISDM", pAllowedConnections As %String = "", pHostIPAddress As %String = "", pArbiterIP As %String = "", pArbiterPort As %Integer = 0, pSSLDirectory As %String = "", pMirrorName As %String = "", pMemberName As %String = "") As %Status [ Internal, Private ]
{
	s status=$$$OK
	new %SNSimpleCluster
	s %SNSimpleCluster=1	
	new $NAMESPACE
	s $NAMESPACE="%SYS"

	$$$SNDebugTrace("Init 1")
	
	// Acquire lock to prevent concurrent attempt to initialize this node.
	lock +$$$SSSysGlobal($$$SSShardingSubscript)
	s locked=1
	
	try {
		// If ^SYS("Sharding","ClusterNamespace")) is already defined, 
		// this node has already been initialized or attached, so don't
		// allow this call
		if $d($$$SSSysGlobal($$$SSShardingSubscript,$$$SSClusterNamespaceSubscript)) {
			if $d($$$SSSysGlobal($$$SSShardingSubscript,$$$SSMasterNamespaceSubscript)) {
				s status=$$$ERROR($$$SHMNodeAlreadyInitialized)
			}
			else {
				s status=$$$ERROR($$$SHMNodeAlreadyAttached)
			}
			throw ##class(%Exception.StatusException).CreateFromStatus(status)
		}
		s pClusterNamespace=$zcvt(pClusterNamespace,"U")
		s pMasterNamespace=$zcvt(pMasterNamespace,"U")
		// Don't permit pre-existing cluster namespace to contain any globals or routines
		if ##class(%SYS.Namespace).Exists(pClusterNamespace) {
			s globalsExist=0,routinesExist=0
			s status=##class(Config.Namespaces).Get(pClusterNamespace,.properties)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			s globalsDatabase=$g(properties("Globals")),routinesDatabase=$g(properties("Routines"))
			s status=##class(Config.Databases).Get(globalsDatabase,.properties)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			s globalsDirectory=properties("Directory")
			s rs=##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
			s status=rs.%Execute(globalsDirectory)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			if rs.%Next() {
				s globalsExist=1
			}
			s status=##class(Config.Databases).Get(routinesDatabase,.properties)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			s routinesDirectory=properties("Directory")
			s rs=##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
			if $d(^|"^^"_routinesDirectory|rINDEX)>=10 || ($d(^|"^^"_routinesDirectory|rINDEXCLASS)>=10) {
				s routinesExist=1
			}
			if globalsExist && routinesExist {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMClusterNamespaceContainsGlobalsAndRoutines,pClusterNamespace))
			}
			elseif globalsExist {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMClusterNamespaceContainsGlobals,pClusterNamespace))

			}
			elseif routinesExist {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMClusterNamespaceContainsRoutines,pClusterNamespace))
			}
		}
		// Don't permit same namespace, or namespaces with same globals or routines databases, to be specified
		// for both cluster namespace and master namespace
		if pClusterNamespace=pMasterNamespace {
			if pMasterNamespace="IRISDM" {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMSameMasterAndClusterNamespace))
			}
			s swapMasterAndShardDatabases=1,pMasterNamespace="IRISDM"
		}
		else {
			s status=##class(Config.Namespaces).Get(pClusterNamespace,.clusterProperties)
			s:status=$$$OK status=##class(Config.Namespaces).Get(pMasterNamespace,.masterProperties)
			if status=$$$OK &&
			   ( $g(clusterProperties("Globals"))=$g(masterProperties("Globals")) ||
			     $g(clusterProperties("Routines"))=$g(masterProperties("Routines")) )
			{
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMSameMasterAndClusterDatabase))
			}
		}
		$$$SNDebugTrace("Init 2")
			
		// If initializing a mirrored cluster, create mirrored set for first node, with this
		// instance as first failover member
		// (CreateMirror is adapted from Builder.ICM)
 		// <b>pMirrorSetName</b>  Mirror Set name<br>             pMirrorName
		// <b>pPrimaryName</b>    Primary member name<br>         pMemberName
		// <b>pPrimaryIP</b>      Primary member IP address<br>   $select(pHostIPAddress="":$$getmyhostname^%SYS.SHARDSRV(),1:pHostIPAddress)
 		// <b>pBackupName</b>     Backup member name<br>          ,
 		// <b>pBackupIP</b>       Backup member IP address<br>    ,
 		// <b>pAgentPort</b>      ISC Agent Port<br>              pAgentPort
 		// <b>pNodeType</b>       "primary" | "backup" | "async"<br>               "primary"
 		// <b>pInstance</b>       Instance name<br>               $p($system,":",2)
 		// <b>pArbiterIP</b>      Arbiter Node IP address<br>     pArbiterIP
 		// <b>pArbiterPort</b>    Arbiter Node port number<br>    pArbiterPort
 		// <b>pSSLdir</b>         SSL/TLS keys directory<br>      pSSLDirectory
		if pMirrored {
			if $system.Mirror.IsMember() {
				if '$system.Mirror.IsPrimary() {
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMNotPrimary))
				}
				s preexistingMirror=1
				s pMirrorName=$system.Mirror.MirrorName()
			}
			else {
				s preexistingMirror=0,agentPort=##class(SYS.MirrorConfiguration).GetAgentPort()
				s status=..CreateMirror(pMirrorName,pMemberName,
										$select(pHostIPAddress="":$$getmyhostname^%SYS.SHARDSRV(),1:pHostIPAddress),
										,,agentPort,"primary",$p($system,":",2),
										pArbiterIP,pArbiterPort,pSSLDirectory)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			}
			$$$SNDebugTrace("Init 3")
		}
		
		// Get the database properties of the globals databases of pMasterNamespace
		// and pClusterNamespace, if either of them already exists.  If one exists and
		// the other doesn't, the one that exists is used as the template for the one
		// that doesn't.
		s status=..GetDbPropsForNamespace(pMasterNamespace,$$$SSMasterDatabaseSubscript,$$$SSDefaultDMDatabase,.masterDbProperties,.masterNamespaceExists,.masterNamespaceIsInteropEnabled)
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		$$$SNDebugTrace("Initialize: masterNamespaceIsInteropEnabled:",$g(masterNamespaceIsInteropEnabled))
		s status=..GetDbPropsForNamespace(pClusterNamespace,$$$SSShardDatabaseSubscript,$$$SSDefaultShardDatabase,.shardDbProperties,.clusterNamespaceExists,.clusterNamespaceIsInteropEnabled)
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		$$$SNDebugTrace("Initialize: clusterNamespaceIsInteropEnabled:",$g(clusterNamespaceIsInteropEnabled))
		
		// If instance is mirror, pre-existing databases must be mirrored, else return error
		if pMirrored {
			if masterNamespaceExists {
				if $g(masterDbProperties("MirrorSetName"))="" {
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMNamespaceNotMirrored,pMasterNamespace))
				}
				// If master namespace has separate routines database, make sure it's mirrored
				s status=##class(Config.Namespaces).Get(pMasterNamespace,.properties)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				s masterRoutinesDbName=$g(properties("Routines"))
				if $g(properties("Globals"))'=masterRoutinesDbName {
					s status=##class(Config.Databases).Get(masterRoutinesDbName,.properties)
					throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
					d getDatabaseProperties^%SYS.SHARDSRV(properties("Directory"),.properties)
					if $g(properties("MirrorSetName"))="" {
						throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMDatabaseNotMirrored,masterRoutinesDbName))
					}
				}
			}
			if clusterNamespaceExists&&($g(shardDbProperties("MirrorSetName"))="") {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMNamespaceNotMirrored,pClusterNamespace))
			}
			$$$SNDebugTrace("Init 4")
		}
		
		// If pMasterNamespace exists, use it as DM namespace.  Else create it.
		if 'masterNamespaceExists {
			$$$SNDebugTrace("Init 5")
			// pMasterNamespace does not exist, create it
			// If a master database is specified, create it if it doesn't exist, else reuse existing.
			// Else, create one with default name, and specified path if specified, else default path.
			// If creating a new master database, use the shard database as a template, if that
			// already exists.
			if clusterNamespaceExists {
				// We don't want to copy the other database's mirror db name
				s shardDbProperties("MirrorDBName")=""
			}
			if +$g(swapMasterAndShardDatabases) {
				s subscript=$$$SSShardDatabaseSubscript,defaultDbName=$$$SSDefaultShardDatabase
			}
			else {
				s subscript=$$$SSMasterDatabaseSubscript,defaultDbName=$$$SSDefaultDMDatabase
			}
			s status=..CreateOrReuseDatabase(subscript,defaultDbName,.masterDbName,.shardDbProperties)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
	
			// Only use a separate master routines database if one is specified.  If so,
			// create it if it doesn't exist using specified path if specified, else default path
			if $g($$$SSSysGlobal($$$SSShardingSubscript,$$$SSMasterRoutinesDatabaseSubscript))'="" {
				s status=..CreateOrReuseDatabase($$$SSMasterRoutinesDatabaseSubscript,"",.masterRoutinesDbName)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			}
			else {
				s masterRoutinesDbName=masterDbName
			}
			// Create master namespace
			k Properties
			s Properties("Globals")=masterDbName,Properties("Routines")=masterRoutinesDbName
			s status=##class(Config.Namespaces).Create(pMasterNamespace,.Properties)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			if clusterNamespaceIsInteropEnabled {
				// Cluster namespace already existed prior to this call, and is interoperability-enabled,
				// so make the master namespace interoperability-enabled as well.
				if (##class(%Library.EnsembleMgr).IsEnsembleInstalled()) {
					s status=##class(%EnsembleMgr).populateIsPrimary(.isPrimary)
					throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
					if isPrimary {
						$$$SNDebugTrace("Initialize: Enabling interoperability for namespace "_pMasterNamespace)
						s status=##class(%Library.EnsembleMgr).EnableNamespace(pMasterNamespace)
  						throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
					}
				}
            }
		}
		$$$SNDebugTrace("Init 6")
		// Else pMasterNamespace exists, simply use it as-is
	
		// If pClusterNamespace exists, its existing globals database will become
		// the shard-local database for this node.
		// Else, create pClusterNamespace, creating or reusing (if one is specified
		// and exists) a database for it, which will become the shard-local database.
		if 'clusterNamespaceExists {
			// pClusterNamespace does not exist, create it
			// If a shard database is specified, create it if it doesn't exist, else reuse existing.
			// Else, create one with default name, and specified path if specified, else default path.
			if masterNamespaceExists {
				// We don't want to copy the other database's mirror db name
				s masterDbProperties("MirrorDBName")=""
			}
			s status=..CreateOrReuseDatabase($$$SSShardDatabaseSubscript,$$$SSDefaultShardDatabase,.shardDbName,.masterDbProperties)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			// Create cluster namespace
			k Properties
			s Properties("Globals")=shardDbName,Properties("Routines")=shardDbName
			s status=##class(Config.Namespaces).Create(pClusterNamespace,.Properties)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			if masterNamespaceIsInteropEnabled {
				// Master namespace already existed prior to this call, and is interoperability-enabled,
				// so make the cluster namespace interoperability-enabled as well.
				if (##class(%Library.EnsembleMgr).IsEnsembleInstalled()) {
					s status=##class(%EnsembleMgr).populateIsPrimary(.isPrimary)
					throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
					if isPrimary {
						s status=##class(%Library.EnsembleMgr).EnableNamespace(pClusterNamespace)
						throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
					}
                }
			}
		}
		$$$SNDebugTrace("Init 7")
		// Else pClusterNamespace exists, simply use it as-is
		if +$g(swapMasterAndShardDatabases) {
			// Specified pre-existing cluster namespace is to be used as cluster namespace, but its databases are
			// to be used as master databases (this is the desired case when converting a non-sharded instance to 
			// sharded data node 1, where non-sharded tables already exist in this namespace, that need to be visible
			// in the cluster namespace).  We accomplish this by swapping, so that the cluster namespace points to the
			// databases previously considered to be the master databases, and the master namespace points to the 
			// databases previously considered to be the shard databases (which will have been newly-created above).
			s status=..SwapDatabases(pMasterNamespace,pClusterNamespace)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		}
		
		// Now that we've successfully gotten or created namespaces and databases,
		// enable sharding 
		s status=$SYSTEM.Sharding.EnableSharding(0,1,pAllowedConnections)
		$$$SNDebugTrace("Init 8")
		
		// Configure the cluster namespace as first shard of the master namespace
		if pHostIPAddress'="" {
			s status=$SYSTEM.Sharding.SetOption(pMasterNamespace,"MasterIPAddress",pHostIPAddress)
			if status=$$$OK {
				s status=$SYSTEM.Sharding.SetNodeIPAddress(pHostIPAddress)
			}
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			s host=pHostIPAddress
		}
		else {
			s host=$$getmyhostname^%SYS.SHARDSRV()
		}
		s status=$SYSTEM.Sharding.AssignShard(pMasterNamespace,host,$$getmydefaultport^%SYS.SHARDSRV,pClusterNamespace,,pMirrorName)
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		$$$SNDebugTrace("Init 9")
		s $$$SSExtendedGlobal(pMasterNamespace)($$$SSSimpleSubscript)=1
		s $$$SSSysGlobal($$$SSShardingSubscript,$$$SSClusterNamespaceSubscript)=pClusterNamespace
		s $$$SSSysGlobal($$$SSShardingSubscript,$$$SSMasterNamespaceSubscript)=pMasterNamespace
		s status=$SYSTEM.Sharding.VerifyShards(pMasterNamespace)
		$$$SNDebugTrace("Init 10")
		if status=$$$OK&&pMirrored {
			if preexistingMirror {
				s status=##class(Config.Mirrors).Get($system.Mirror.MirrorName(),.properties)
				if status=$$$OK&&($g(properties("ArbiterNode"))'="") {
					s arbiterNode=properties("ArbiterNode")
					s arbiterIP=$p(arbiterNode,"|",1)
					s arbiterPort=$p(arbiterNode,"|",2)
					s $$$SSExtendedGlobal(pMasterNamespace)($$$SSShardsSubscript,-1,$$$SSArbiterSubscript)=$lb(arbiterIP,arbiterPort)
					s $$$SSExtendedGlobal(pMasterNamespace)($$$SSShardsSubscript,1,$$$SSArbiterSubscript)=$lb(arbiterIP,arbiterPort)
				}
				if +$g(swapMasterAndShardDatabases) {
					s $$$SSExtendedGlobal(pMasterNamespace)($$$SSSwapDbsSubscript)=1
				}
			}
			else {
				s arbiterIP=pArbiterIP
				s arbiterPort=pArbiterPort
			}
			new $namespace
			s $namespace=pClusterNamespace
			s $$$SSGlobal($$$SSMirrorSequenceSubscript)=1
			if $g(arbiterIP)'="" {
				s $$$SSGlobal($$$SSShardsSubscript,-1,$$$SSArbiterSubscript)=$lb(arbiterIP,arbiterPort)
				s $$$SSGlobal($$$SSShardsSubscript,1,$$$SSArbiterSubscript)=$lb(arbiterIP,arbiterPort)
			}
			if pSSLDirectory'=""&&'preexistingMirror {
				d setSSLDirectory^%SYS.SHARDSRV(pSSLDirectory)
			}
		}
		$$$SNDebugTrace("Init 11")
	}
	catch ex {
		s status=ex.AsStatus()
	}
	if status=$$$OK {
		d setNodeInitialized^%SYS.SHARDSRV(1)
	}
	lock:locked -$$$SSExtendedSysGlobal($$$SSShardingSubscript)#"I" // JMM1175=
	$$$SNDebugTrace("Init 12")
	return status
}

/// Attaches the current InterSystems IRIS instance to a specified cluster as a nonmirrored data node.
/// <p>This method automatically and transparently performs all steps needed
/// to enable this instance as a data node of the specified cluster (subject to
/// these <a href="#Prerequisites">prerequisites</a>), including:</p>
/// <ul>
/// <li>Enables the ECP and sharding services, and sets these
///   services' lists of allowed connections to match the lists on the node
///   specified by pClusterURL.</li>
/// <li>Creates the cluster namespace and shard database if they
///   don't already exist, configuring them to match the settings on the node
///   specified by pClusterURL.</li>
/// <li>Creates all necessary mappings from the cluster namespace to the
///   globals and routines databases of the master namespace on node 1, and
///   to the shard database on the current instance.</li>  
/// <li>Propagates any user-defined mappings from the master namespace on node 1 
///   to the cluster namespace on the current instance.</li>
/// <li> Sets all SQL configuration options to match their settings on the
///   node specified by pClusterURL. </li>
/// </ul>
/// <p>If a data node has been flagged for pending removal by calling <method>Detach</method> while
/// sharded tables exist, and the node's removal has not yet been completed by calling <method>Rebalance</method>,
/// the pending removal can be cancelled by calling <b>AttachAsDataNode</b>.   In that case, the <i>pHostIPAddress</i>
/// parameter is ignored, and an error is returned if the <i>pClusterURL</i> parameter does not specify a node
/// of the current cluster.  Call <method>ListNodes</method> to determine whether a node is flagged for pending removal.</p>
/// <p>This method returns an error in any of the following cases:</p>
/// <ul>
/// <li>The current InterSystems IRIS instance is already a node of a sharded cluster.</li>
/// <li>The current instance is a mirror member.</li>
/// <li>The specified cluster namespace already exists, and its globals database is mirrored.</li>
/// <li>The node specified by pClusterURL is mirrored.</li>
/// <li>The current instance is a node of a sharded cluster, flagged for pending removal, and the node specified
/// by <i>pClusterURL</i> is not a node of the same cluster.</li>
/// </ul>
/// <p><b>Parameters:</b></p>
/// <dl>
/// <dt><i>pClusterURL</i></dt>
/// <dd>Identifies the cluster to which to attach, by specifying the address of any existing node of the cluster, 
///  in the format "IRIS://<i>host</i>:<i>port</i>/<i>cluster-namespace</i>". Namespace may optionally be omitted, since
///  there can be at most one cluster namespace in an InterSystems IRIS instance.
///  </dd>
/// <dt><i>pHostIPAddress</i></dt>
/// <dd>IP address other nodes of this cluster should use to connect to this node.  Specify a value for
///  for this parameter if the default hostname known to InterSystems IRIS does not resolve to an appropriate address, or no hostname is available.
///  Default: Default hostname will be used for inter-node connections. 
/// </dd>
/// </dl>
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.</dd>
/// </dl>
/// <p><b>Notes:</b></p>
/// <ul>
/// <li>A cluster namespace, with same name as on all other nodes of this cluster,
/// is created if a namespace of that name doesn't already exist.
/// If it does already exist, its globals database becomes the shard database for 
/// this node.</li>
/// <li>If the node specified by pClusterURL is a data node, it is used as the template
/// for configuration settings on this node.  If the specified 
/// node is a compute node, the corresponding data node is used as the template.</li>
/// <li>If the cluster namespace doesn't exist, it is created with interoperability
/// enabled or not according to whether it is enabled for the cluster namespace
/// on the template node, and with its globals database settings,
/// including directory path, matching those of the shard database on the template
/// node.</li>
/// <li>All SQL configuration settings are set to match those on the template node.</li>
/// <li>Data nodes are assigned a numeric id, in sequence starting from 1, in the
/// order they are attached to the cluster.  A data node's id is the same as 
/// its shard number.  Nodes are listed by id by <method>ListNodes</method> and 
/// <method>GetMetadata</method>.</li>
/// </ul>
ClassMethod AttachAsDataNode(pClusterURL As %String, pHostIPAddress As %String = "") As %Status
{
	return:$system.Mirror.IsMember() $$$ERROR($$$SHMInstanceCannotBeMirrored,"$SYSTEM.Cluster.AttachAsDataNode()")
	return ..Attach($$$SSNodeTypeData,$g(pClusterURL),pHostIPAddress)
}

/// Attaches the current InterSystems IRIS instance to a specified cluster as a compute node.
/// <p>This method automatically and transparently performs all steps needed
/// to enable this instance as a compute node of the specified cluster (subject to
/// these <a href="#Prerequisites">prerequisites</a>), including:</p>
/// <ul>
/// <li>Enables the ECP and sharding services, and sets these
///   services' lists of allowed connections to match the lists on the node
///   specified by pClusterURL.</li>
/// <li>Creates the cluster namespace if it
///   doesn't already exist, configuring it to match the settings on the node
///   specified by pClusterURL.</li>
/// <li>Associates this compute node with a data node that previously had
///   the minumum number of associated compute nodes, so as to automatically
///   balance compute nodes across data nodes.</li>
/// <li>Creates all necessary mappings from the cluster namespace to the
///   globals and routines databases of the master namespace on node 1, and
///   to the shard database on the the associated data node. </li> 
/// <li>Propagates any user-defined mappings from the master namespace on node 1 
///   to the cluster namespace on the current instance.</li>
/// <li>Sets all SQL configuration options to match their settings on the
///   node specified by pClusterURL. </li>
/// </ul>
/// <p>This method returns an error if the current InterSystems IRIS instance 
/// is already a node of a sharded cluster.</p>
/// <p><b>Parameters:</b></p>
/// <dl>
/// <dt><i>pClusterURL</i></dt>
/// <dd>Identifies the cluster to which to attach, by specifying the address of any existing node of the cluster, 
///  in the format "IRIS://<i>host</i>:<i>port</i>/<i>cluster-namespace</i>". Namespace may optionally be omitted, since
///  there can be at most one cluster namespace in an InterSystems IRIS instance.</dd>
/// <dt><i>pHostIPAddress</i></dt>
/// <dd>IP address other nodes of this cluster should use to connect to this node.  Specify a value for
///  for this parameter if the default hostname known to InterSystems IRIS does not resolve to an appropriate address, or no hostname is available.
///  Default: Default hostname will be used for inter-node connections. 
/// </dd>
/// </dl>
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.</dd>
/// </dl>
/// <p><b>Notes:</b></p>
/// <ul>
/// <li>A cluster namespace, with same name as on all other nodes of this cluster,
/// is created if a namespace of that name doesn't already exist.
/// Note that if it does already exist, its globals database is "orphaned",
/// as the global database of the cluster namespace is mapped to the globals
/// database of the master namespace on node 1, and a compute node does not
/// need to reuse this database as a shard database.</li>
/// <li>If the cluster namespace doesn't exist, it is created with interoperability
/// enabled or not according to whether it is enabled for the cluster namespace
/// on the node specified by pClusterURL.</li>
/// <li>All SQL configuration settings are set to match those on the node
/// specified by pClusterURL.
/// <li>Compute nodes are assigned a numeric id, in sequence starting from 1001, 
/// in the order they are attached to the cluster.  
/// Nodes are listed by id by <method>ListNodes</method> and 
/// <method>GetMetadata</method>.</li>
/// </ul>
ClassMethod AttachAsComputeNode(pClusterURL As %String, pHostIPAddress As %String = "") As %Status
{
	return:$system.Mirror.IsMember() $$$ERROR($$$SHMInstanceCannotBeMirrored,"$SYSTEM.Cluster.AttachAsComputeNode()")
	return ..Attach($$$SSNodeTypeCompute,$g(pClusterURL),pHostIPAddress)
}

/// Attaches the current InterSystems IRIS instance to a specified cluster as a mirrored data node.
/// <p>This method automatically and transparently performs all steps needed
/// to enable this instance as a data node of the specified cluster (subject to
/// these <a href="#Prerequisites">prerequisites</a>), including: </p>
/// <ul>
/// <li>Enables the ECP and sharding services, and sets the sharding
///   services' lists of allowed connections to match the lists on the node
///   specified by pClusterURL.</li>
/// <li>If the current instance is not already a member of a mirror, performs
///   mirror configuration according to role specified by pMemberRole:
///   <ul>
///   <li><i>"primary"</i> 
///   Creates a new mirror set, and configures the current instance as its first
///   failover member.</li>
///   <li><i>"backup"</i>
///   Configures the current instance as the backup failover member of the mirror set
///   whose primary failover member is specified by pClusterURL.</li>
///   <li><i>"drasync"</i>
///   Configures the current instance as a DR async member of the mirror set
///   whose primary failover member is specified by pClusterURL.</li>
///   </ul></li>
/// <li>Creates the cluster namespace and shard database if they
///   don't already exist, configuring them to match the settings on the node
///   specified by pClusterURL.  If pMemberRole is <i>"backup"</i> and pClusterURL
///   specifies node 1 of this cluster, also creates the master namespace and
///   master database if they don't already exist.</li>
/// <li> Creates all necessary mappings from the cluster namespace to the
///   globals and routines databases of the master namespace on node 1, and
///   to the shard database on the current instance.  (Mappings are not created when pMemberRole is "drasync".)</li>
/// <li>Propagates any user-defined mappings from the master namespace on node 1 
///   to the cluster namespace on the current instance.  (Mappings are not propagated when pMemberRole is "drasync".)</li>
/// <li>Sets all SQL configuration options to match their settings on the
///   node specified by pClusterURL. </li>
/// </ul>
/// <p>If a mirrored node has been flagged for pending removal by calling <method>Detach</method> while sharded
/// tables exist, and the node's removal has not yet been completed by calling the <class>%SYSTEM.Sharding</class> <b>Rebalance</b> method, the
/// pending removal can be cancelled by calling <b>AttachAsMirroredNode</b>.  In that case, all parameters
/// except pClusterURL and pMemberRole are ignored.  pMemberRole may be specified as either
/// <i>"primary"</i> or <i>"backup"</i>, regardless of the current instance's current failover role, but if <i>"backup"</i> is specified,
/// then an error is returned if pClusterURL does not specify the other failover member of this mirror.  Call 
/// <method>ListNodes</method> to determine whether a node is flagged for pending removal.</p>
/// <p>This method returns an error in any of the following cases:</p>
/// <ul>
/// <li>The current InterSystems IRIS instance is already a node of a sharded cluster.</li>
/// <li>The specified cluster namespace already exists, and its globals database is not mirrored.</li>
/// <li>pMemberRole is <i>"backup"</i>, pClusterURL specifies node 1 of this cluster, and a 
/// namespace with the same name as the master namespace already exists, and is not mirrored.</li>
/// <li>The node specified by pClusterURL is not mirrored.</li>
/// <li>pMemberRole is <i>"backup"</i>, and the node specified by pClusterURL belongs to a mirror
/// set which already has two failover members.</li>
/// <li>The current instance is a member of an existing mirror set, in a role different from the one
/// specified by pMemberRole.</li>
/// <li>The current instance is a backup or DR async member of a different mirror set than the node specified
/// by pClusterURL.</li>
/// <li>pMemberRole is <i>"backup"</i>, and one of the backup databases created by this method could
/// be caught up within two minutes. This is rare, and is most likely due to a delay in this instance
/// becoming an active mirror backup member (check messages.log for possible causes). In this event,
/// the error message "Cannot catch up database <i>dbname</i>, manual catchup required" is returned.
/// The method <method>CatchupDB</method> can be used to perform manual catchup.</li>
/// <li>The current instance is a node of a sharded cluster, flagged for pending removal, and the node 
/// specified by pClusterURL is not a node of the same cluster.</li>
/// <li>The current instance is a node of a sharded cluster, flagged for pending removal, and pMemberRole is
/// <i>"backup"</i>, but pClusterURL does not specify a node of the same cluster.</li>
/// </ul>
/// <p><b>Parameters:</b></p>
/// <dl>
/// <dt><i>pClusterURL</i></dt>
/// <dd>Identifies the cluster to which to attach, by specifying the address of am existing node of the cluster, 
///  in the format "IRIS://<i>host</i>:<i>port</i>/<i>cluster-namespace</i>". Namespace may optionally be omitted, since
///  there can be at most one cluster namespace in an InterSystems IRIS instance. If pMemberRole is <i>"primary"</i>, 
///  pClusterURL may specify any existing node.  If pMemberRole is <i>"backup"</i>, pClusterURL
///  must specify the node which is the primary failover member of the mirror set for which the current instance will
///  be attached as the backup failover member.</dd>
/// <dt><i>pMemberRole</i>
///  This node's role as a mirror member:</dt>
/// <dd><ul>
///  <li><i>"primary"</i> Attach as primary failover member.</li>
///  <li><i>"backup"</i> Attach as backup failover member of mirror whose primary failover member is specified by pClusterURL.</li>
///  <li><i>"drasync"</i> Attach as DR async member of mirror whose primary failover member is specified by pClusterURL.</li>
/// </ul></dd>
/// <dt><i>pHostIPAddress</i></dt>
/// <dd>IP address other nodes of this cluster should use to connect to this node.  Specify a value for
///  for this parameter if the default hostname known to InterSystems IRIS does not resolve to an appropriate address, or no hostname is available.
///  Default: Default hostname will be used for inter-node connections. 
/// </dd>
/// <dt><i>pArbiterIP</i></dt>
/// <dd>Arbiter's hostname or IP address. Specify a non-null value to configure this mirror to use an arbiter, overriding the value inherited from the node specified by 
/// <i>pClusterURL</i>.
/// Ignored when attaching a backup failover member.</dd>
/// <dt><i>pArbiterPort</i></dt>
/// <dd>Arbiter's port. Specify a non-zero value to configure this mirror to use an arbiter, overriding the value inherited
/// from the node specified by <i>pClusterURL</i>. Ignored when attaching a backup failover member.</dd>
/// <dt><i>pSSLDirectory</i></dt>
/// <dd>SSL/TLS keys directory. Specify a non-null value to configure this mirror to use SSL/TLS, overriding the value 
/// inherited from the node specified by <i>pClusterURL</i>. Directory is expected to
/// contain three files named "CAFile.pem", "CertificateFile.pem, and "PrivateKeyFile.pem".</dd>
/// <dt><i>pMirrorName</i></dt>
/// <dd>Name of mirror set to create. Default: IRISMIRROR<i>N</i>, where <i>N</i> is a mirror naming sequence number unique within this
/// cluster (usually the same as the node id).</dd>
/// <dt><i>pMemberName</i></dt>
/// <dd>Name by which this instance is known to the mirror. Default: The mirror name, with the letter 'A' appended for the primary failover
/// member, or 'B' for the backup failover member.</dd>
/// </dl>
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// </dl>
/// <p><b>Notes:</b></p>
/// <ul>
/// <li>Mirrored data nodes are always paired, and both members of a pair are assigned the same node id.
/// Each instance of the pair is attached by a separate call to
/// AttachAsMirroredNode, specifying pMemberRole as <i>"primary"</i> for the first node attached, and
/// as <i>"backup"</i> for the second node attached.  These specify
/// the initial roles, which are swapped when the mirror fails over. Use <method>ListNodes</method> to
/// determine the current member roles of all mirrored nodes.
/// <li>If the current instance is already a mirror member, the mirror configuration parameters (pArbiterIP, 
/// pArbiterPort, pSSLDirectory, pMirrorName, and pMemberName) are ignored, and the mirror 
/// configuration is not modified.</li>
/// <li>If any of the arguments pArbiterIP, pArbiterPort, or pSSLDirectory is not specified,
/// the values configured for the node specified by pClusterURL are used.</li>
/// <li>Recommended best practice is to attach both failover members of a mirror set, before storing
/// any data in the cluster database. In the case of creating a new mirror set, data stored in the
/// primary member is not backed up until the backup member has been attached.  In the case of attaching
/// the failover members of an existing mirror set, if only the primary failover member has been attached,
/// and the mirror fails over, sharded operations on the cluster cannot access data on other failover
/// member that has been promoted from backup to primary, until it has been attached to the cluster.</li>
/// <li>When attaching the failover members of an existing mirrored set, attach the current primary member
/// first, then the current backup member.  The node being attached as primary must actually be
/// primary at the time it is attached, and the node being attached as backup must actually be backup
/// at the time it is attached.</li>
/// <li>A cluster namespace, with same name as on all other nodes of this cluster,
/// is created if a namespace of that name doesn't already exist.
/// If it does already exist, its globals database becomes the shard database for 
/// this node.</li>
/// <li>If the node specified by pClusterURL is a data node, it is used as the template
/// for configuration settings on this node.  If the specified 
/// node is a compute node, the corresponding data node is used as the template.</li>
/// <li>If the cluster namespace doesn't exist, it is created with interoperability
/// enabled or not according to whether it is enabled for the cluster namespace
/// on the template node, and with its globals database settings,
/// including directory path, matching those of the shard database on the template
/// node.</li>
/// <li>All SQL configuration settings are set to match those on the template node.</li>
/// <li>Data nodes are assigned a numeric id, in sequence starting from 1, in the
/// order they are attached to the cluster.  A data node's id is the same as 
/// its shard number.  Nodes are listed by id by <method>ListNodes</method> and 
/// <method>GetMetadata</method>.</li>
/// </ul>
ClassMethod AttachAsMirroredNode(pClusterURL As %String, pMemberRole As %String, pHostIPAddress As %String = "", pArbiterIP As %String = "", pArbiterPort As %Integer = 0, pSSLDirectory As %String = "", pMirrorName As %String = "", pMemberName As %String = "") As %Status
{
	if $g(pMemberRole)="" {
		return $$$ERROR($$$SHMMissingParameter,"pMemberRole")
	}
	s pMemberRole=$zcvt($g(pMemberRole),"L")
	// Validate member role (TBD: Also support DRAsync)
	if pMemberRole'=$$$SSMemberRolePrimary&&(pMemberRole'=$$$SSMemberRoleBackup)&&(pMemberRole'=$$$SSMemberRoleDRAsync) {
		return $$$ERROR($$$InvalidArgument)
	}
	if (pArbiterIP'=""&&(pArbiterPort=0))||(pArbiterIP=""&&(pArbiterPort'=0)) {
		return $$$ERROR($$$SHMIncompleteArbiterAddress)
	}
	return ..Attach($$$SSNodeTypeMirror,$g(pClusterURL),pHostIPAddress,pMemberRole,
					pArbiterIP,pArbiterPort,pSSLDirectory,pMirrorName,pMemberName)
}

ClassMethod Attach(pNodeType As %String = "", pClusterURL As %String, pHostIPAddress As %String = "", pMemberRole As %String = "primary", pArbiterIP As %String = "", pArbiterPort As %Integer = 0, pSSLDirectory As %String = "", pMirrorName As %String = "", pMemberName As %String = "") As %Status [ Internal, Private ]
{
	new %SNDatabasesNeedingCatchup
	if $g(pClusterURL)="" {
		return $$$ERROR($$$SHMMissingParameter,"pClusterURL")
	}
	s:pNodeType="" pNodeType=$$$SSNodeTypeData
	s status=$$$OK
	new $NAMESPACE
	s $NAMESPACE="%SYS"

	// Acquire lock to prevent concurrent attempt to initialize this node.
	lock +$$$SSSysGlobal($$$SSShardingSubscript)
	s locked=1
	
	try {
		// If ^SYS("Sharding","ClusterNamespace")) is already defined, 
		// this node has already been initialized or attached, so don't
		// allow this call
		if $d($$$SSSysGlobal($$$SSShardingSubscript,$$$SSClusterNamespaceSubscript)) {
			// JMM1109: Check whether this node is pending removal. If so, treat this case as an effort to cancel the pending removal.
			if 1 {
				s previousClusterNamespace=$g($$$SSSysGlobal($$$SSShardingSubscript,$$$SSClusterNamespaceSubscript))
				s $NAMESPACE=previousClusterNamespace
				s host=$select(pHostIPAddress="":$$getmyhostname^%SYS.SHARDSRV(),1:pHostIPAddress)
				s shard=$lb(host,^%SYS("SSPort"),previousClusterNamespace)
				s status=$$parseClusterURL^%SYS.SHARDSRV(pClusterURL,.url)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				// Make sure we're trying to attach to the same cluster as previously
				s urlShard=$lb(url("Host"),url("Port"),previousClusterNamespace)
				s master=$g($$$SSGlobal($$$SSShardsSubscript,-1))
				if $$shardAddrsEqual^%SYS.SHARDSRV(urlShard,master) || ##class(%BigData.ShardingManager).AlreadyAssigned(urlShard) {
					// Ok, same cluster as before. Is this shard pending removal?
					if $$pendingRemoval^%SYS.SHARDSRV(shard,.shardNumber) {
						// Yes, so just cancel the pending removal.
						new %SNSimpleCluster
						s %SNSimpleCluster=1
						if pMemberRole'="" {
							s mirrorName=pMirrorName
							if mirrorName="" {
								s mirrorName=$g($$$SSGlobal($$$SSShardsSubscript,shardNumber,$$$SSMirrorNameSubscript))
							}
							else {
								if $zcvt(mirrorName,"U")'=$system.Mirror.MirrorName() {
									throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMMemberOfAnotherMirror))
								}
							}
							if $zcvt(pMemberRole,"L")="backup" {
								// Make sure cluster URL specifies this node's mirror partner
								for ii=1:1: $$$SSGlobal($$$SSShardsSubscript) {
									s partner=""
									if $$shardAddrsEqual^%SYS.SHARDSRV(shard,$$$SSGlobal($$$SSShardsSubscript,ii)) {
										s partner=$g($$$SSGlobal($$$SSShardsSubscript,ii,$$$SSMirrorBackupSubscript))
									}
									elseif $$shardAddrsEqual^%SYS.SHARDSRV(shard,$g($$$SSGlobal($$$SSShardsSubscript,ii,$$$SSMirrorBackupSubscript))) {
										s partner=$$$SSGlobal($$$SSShardsSubscript,ii)
									}
									if partner'="" {
										if '$$shardAddrsEqual^%SYS.SHARDSRV(partner,urlShard) && '$$shardAddrsEqual^%SYS.SHARDSRV(shard,urlShard) {
											throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMPendingRemovalDifferentFailoverMembers,$lg(shard,1),$lg(shard,2),$lg(shard,3),$lg(partner,1),$lg(partner,2),$lg(partner,3)))
										}
										q
									}
								}
								if partner="" && '$$shardAddrsEqual^%SYS.SHARDSRV(shard,urlShard) {
									throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMPendingRemovalNoBackup,$lg(shard,1),$lg(shard,2),$lg(shard,3)))
								}
							}
						}
						else {
							s mirrorName=""
						}
						s status=$system.Sharding.AssignShard(,$lg(shard,1),$lg(shard,2),$lg(shard,3),,mirrorName)
						lock:locked -$$$SSExtendedSysGlobal($$$SSShardingSubscript)#"I" // JMM1175=
						return status
					}
				}
				// Else, not the same cluster we were attached to before, so don't allow this
			}
			if $d($$$SSSysGlobal($$$SSShardingSubscript,$$$SSMasterNamespaceSubscript)) {
				s status=$$$ERROR($$$SHMNodeAlreadyInitialized)
			}
			else {
				s status=$$$ERROR($$$SHMNodeAlreadyAttached)
			}
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		}
		// Connect to specified cluster node
		s status=$$parseClusterURL^%SYS.SHARDSRV(pClusterURL,.url)
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		// Make sure caller isn't mistakenly specifying this node's address as cluster URL
		if $$hostsEqual^%SYS.SHARDSRV(url("Host"),$$getmyhostname^%SYS.SHARDSRV())&&(url("Port")=$$getmydefaultport^%SYS.SHARDSRV()) {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMCannotAttachToSelf))
		}
		// In case this node was previously attached, and then detached, while this job was connected, reset com to avoid tripping over
		// stale devices
		$$$SSForceReconnectAllShards
		k %SNCom
		s $SYSTEM.Context.SN().com=##class(%BigData.TCPMessaging).%New("")
		if pNodeType=$$$SSNodeTypeMirror {
			s isMember=$system.Mirror.IsMember()
			if isMember {
				s isPrimary=0,isBackup=0,isDRAsync=0
				if isMember=1 {
					if $system.Mirror.IsPrimary() {
						s isPrimary=1
					}
					elseif $system.Mirror.IsBackup() {
						s isBackup=1
					}
				}
				elseif isMember=2 {
					s isDRAsync=1
				}
				if pMemberRole=$$$SSMemberRolePrimary && 'isPrimary {
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMNotPrimary))
				}
				elseif pMemberRole=$$$SSMemberRoleBackup && 'isBackup {
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMNotBackup))
				}
				elseif pMemberRole=$$$SSMemberRoleDRAsync && 'isDRAsync {	
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMNotDRAsync))
				}
				elseif $g(pMirrorName)'="" && ($zcvt(pMirrorName,"U")'=$system.Mirror.MirrorName()) {
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMMemberOfAnotherMirror))
				}
				s preexistingMirror=1
			}
			else {
				s preexistingMirror=0
			}	
			s nodeType=pMemberRole
		}
		else {
			s nodeType=pNodeType
		}
		n %SNPrimaryHost,%SNPrimaryPort
		s retry=0
		do {
			s status=$$connect^%SYS.SHARDSRV(.dev,url("Host"),url("Port"),url("Namespace"),$$$SSTCPMessaging,0,,,1)
			if status'=$$$OK {
				if ##class(%SYSTEM.Status).GetErrorCodes(status)=$$$ERRORCODE($$$SHMShardNotPrimary) {
					if $g(%SNPrimaryHost)'=""&&($g(%SNPrimaryPort)'="") {
						s url("Host")=%SNPrimaryHost,url("Port")=%SNPrimaryPort
						s retry='retry
					}
				}
				throw:'retry ##class(%Exception.StatusException).CreateFromStatus(status)
			}
			else {
				s retry=0
			}
		} while retry
		s msg=$$$SSMsgCodeRequestAttach_$lb(url("Namespace"),nodeType)
		if nodeType=$$$SSMemberRolePrimary||(nodeType=$$$SSMemberRoleBackup)||(nodeType=$$$SSMemberRoleDRAsync) {
			if pMirrorName'="" {
				s msg=msg_$lb(pMirrorName,"","")
			}
			elseif preexistingMirror {
				s msg=msg_$lb($system.Mirror.MirrorName(),$$getmyhostname^%SYS.SHARDSRV(),$$getmydefaultport^%SYS.SHARDSRV())
			}
			s msg=msg_$lb(preexistingMirror)
		}
		d $$$SNCom.clisend(dev,msg)
		s reply=$$$SNCom.clirecv(dev)
		s status=$lg(reply)
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		s allowedIPs=$lg(reply,2),clusterNamespace=$lg(reply,3),settings=$lg(reply,4)
		s enableInterop=$lg(settings,1),dbSettings=$lg(settings,2),sqlSettings=$lg(settings,3),
		  masterDbSettings=$lg(settings,4),masterRoutinesDbSettings=$lg(settings,5)
		if pNodeType=$$$SSNodeTypeMirror {
			s mirrorInfo=$lg(reply,5)
			s mirrorName=$lg(mirrorInfo,1),mirrorSequenceNumber=$lg(mirrorInfo,2),shardNumber=$lg(mirrorInfo,3),
			  primaryNetworkAddress=$lg(mirrorInfo,4),primaryISCAgentPort=$lg(mirrorInfo,5),
			  arbiterIP=$lg(mirrorInfo,6),arbiterPort=$lg(mirrorInfo,7),
			  masterNamespace=$lg(mirrorInfo,8),
			  masterEnableInterop=$lg(mirrorInfo,9),primaryInstanceName=$lg(mirrorInfo,10),
			  sslDirectory=$lg(mirrorInfo,11),memberNameSequence=$lg(mirrorInfo,12),swapDbs=$lg(mirrorInfo,13)
			s agentPort=##class(SYS.MirrorConfiguration).GetAgentPort()
			if $system.Mirror.IsMember() {
				s pMirrorName=$system.Mirror.MirrorName()
				if pMemberRole=$$$SSMemberRoleBackup&&(pMirrorName'=mirrorName) {
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMWrongMirror,pMirrorName,mirrorName))
				}
				elseif pMemberRole=$$$SSMemberRoleDRAsync&&(pMirrorName'=mirrorName) {
					throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMWrongMirrorForAsync,pMirrorName,mirrorName))
				}
			}
			else {
				if pArbiterIP'="" {
					s arbiterIP=pArbiterIP
				}
				if pArbiterPort'=0 {
					s arbiterPort=pArbiterPort
				}
				if pSSLDirectory'="" {
					s sslDirectory=pSSLDirectory
				}
				if pMemberRole=$$$SSMemberRolePrimary {
					if pMirrorName'="" {
						s mirrorName=pMirrorName
					}
					else {
						s mirrorName="IRISMIRROR"_mirrorSequenceNumber
					}
					if pMemberName'="" {
						s memberName=pMemberName
					}
					else {
						s memberName=mirrorName_"A"
					}
					s status=..CreateMirror(mirrorName,memberName,
											$select(pHostIPAddress="":$$getmyhostname^%SYS.SHARDSRV(),1:pHostIPAddress),
											,,agentPort,"primary",$p($system,":",2),
											arbiterIP,arbiterPort,sslDirectory)
				}
				elseif pMemberRole=$$$SSMemberRoleBackup||(pMemberRole=$$$SSMemberRoleDRAsync) {
					if pMemberName'="" {
						s memberName=pMemberName
					}
					else {
						s memberName=mirrorName_"B"_+$g(memberNameSequence)
					}
	 			 	// If mirror has async failover members, previously demoted from backup members that were
	 			 	// attached with the $SYSTEM.Cluster API, then the name we generated for this backup member
				  	// might not be unique.  If so, keep retrying with successive numeric suffixes, up to 20 tries.
				 	s suffix=""
				 	if pMemberRole=$$$SSMemberRoleBackup {
					 	s role="backup"
				 	}
				 	else {
					 	s role="async"
				 	}
				 	do {
   	  		  			s status=..CreateMirror(mirrorName,,primaryNetworkAddress,memberName_suffix,
									  			$select(pHostIPAddress="":$$getmyhostname^%SYS.SHARDSRV(),1:pHostIPAddress),
												primaryISCAgentPort,role,primaryInstanceName,
												arbiterIP,arbiterPort,sslDirectory)
  	  		  			if $$$ISERR(status) {
	  		  	  			if ##class(%SYSTEM.Status).GetErrorCodes(status)=$$$ERRORCODE($$$MirrorNameNotUnique) {
			  	  	  			s suffix=$i(suffix)
	  		  	  			}
  				  			else {
	  			  				throw ##class(%Exception.StatusException).CreateFromStatus(status)
  				 			 }
  	  	  				}
	  				} while $$$ISERR(status)&&(suffix<20)
				}
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			}
			// If using SSL/TLS, need to add pending mirror member on primary
			if pSSLDirectory'="" && (pMemberRole=$$$SSMemberRoleDRAsync) {
				s msg=$$$SSMsgCodeAddPendingMirrorMember_$lb(memberName)
				d $$$SNCom.clisend(dev,msg)
				s reply=$$$SNCom.clirecv(dev)
				s status=$lg(reply)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)		
			}
		}
		$$$SNDebugTrace("Attach: settings:",settings)
		d listToProps^%SYS.SHARDSRV(dbSettings,.dbProperties)
		s directory=$g(dbProperties("Directory"))
		if $extract(directory,1,$l($$$SSMgrDirPlaceholder))=$$$SSMgrDirPlaceholder {
			s $extract(directory,1,$l($$$SSMgrDirPlaceholder))=##class(%File).NormalizeDirectory($zu(12))
			s dbProperties("Directory")=directory
		}
		if masterDbSettings'="" {
			d listToProps^%SYS.SHARDSRV(masterDbSettings,.masterDbProperties)
			s masterDirectory=$g(masterDbProperties("Directory"))
			if $extract(masterDirectory,1,$l($$$SSMgrDirPlaceholder))=$$$SSMgrDirPlaceholder {
				s $extract(masterDirectory,1,$l($$$SSMgrDirPlaceholder))=##class(%File).NormalizeDirectory($zu(12))
				s masterDbProperties("Directory")=masterDirectory
			}
		}
		if masterRoutinesDbSettings'="" {
			d listToProps^%SYS.SHARDSRV(masterRoutinesDbSettings,.masterRoutinesDbProperties)
			s masterRoutinesDirectory=$g(masterRoutinesDbProperties("Directory"))
			if $extract(masterRoutinesDirectory,1,$l($$$SSMgrDirPlaceholder))=$$$SSMgrDirPlaceholder {
				s $extract(masterRoutinesDirectory,1,$l($$$SSMgrDirPlaceholder))=##class(%File).NormalizeDirectory($zu(12))
				s masterRoutinesDbProperties("Directory")=masterRoutinesDirectory
			}
		}
		d listToProps^%SYS.SHARDSRV(sqlSettings,.sqlProperties)
		// Create the cluster namespace and shard database
		// If clusterNamespace exists, its existing globals database will become
		// the shard-local database for this node.
		// Else, create clusterNamespace, creating or reusing (if one is specified
		// and exists) a database for it, which will become the shard-local database.
		s status=##class(Config.Namespaces).Get(clusterNamespace,.clusterNamespaceProperties)
		if status'=$$$OK {
			s errorCode=##class(%SYSTEM.Status).GetErrorCodes(status)
			if errorCode=$$$ERRORCODE($$$CPFNameDoesNotExist) {
				// clusterNamespace does not exist, create it
				if pNodeType=$$$SSNodeTypeCompute {
					// For a compute node, just create the namespace with IRISTEMP as its
					// default database - we don't need a shard-local database, and AssignShard()
					// will change this to point to the shard database of the associated data shard.
					s shardDbName="IRISTEMP"
				}
				else {
					// If a shard database is specified, create it if it doesn't exist, else reuse existing.
					// Else, create one with default name, and specified path if specified, else default path.
					s status=..CreateOrReuseDatabase($$$SSShardDatabaseSubscript,$$$SSDefaultShardDatabase,.shardDbName,.dbProperties)
					throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				}
				// Create cluster namespace
				k Properties
				s Properties("Globals")=shardDbName,Properties("Routines")=shardDbName
				s status=##class(Config.Namespaces).Create(clusterNamespace,.Properties)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				// Enable interoperability, if it is enabled in cluster namespace on template node
				if enableInterop {
					if (##class(%Library.EnsembleMgr).IsEnsembleInstalled()) {
						s status=##class(%EnsembleMgr).populateIsPrimary(.isPrimary)
						throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
						if isPrimary {
							s status=##class(%Library.EnsembleMgr).EnableNamespace(clusterNamespace)
  							throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
						}
					}
				}
			}
			else {
				// Attempt to get namespace returned error than "NameDoesNotExist"
				$$$SNDebugTrace("Attach 2 status:",status)
				throw ##class(%Exception.StatusException).CreateFromStatus(status)
			}
		}
		// Else clusterNamespace exists, simply use it as-is, unless we're attaching a mirror backup or
		// async to node 1, and this is a "swapDbs" scenario, in which case the pre-existing database of the
		// cluster namespace should become the master database, rather than the shard database.
		elseif $system.Mirror.IsMember()&&'$system.Mirror.IsPrimary() {
			if +$g(swapDbs) && (pNodeType=$$$SSNodeTypeMirror)&&(pMemberRole=$$$SSMemberRoleBackup||(pMemberRole=$$$SSMemberRoleDRAsync))&&(shardNumber=1) {
				s status=##class(Config.Namespaces).Get(masterNamespace,.properties)
				if status=$$$OK {
					// "SwapDbs" scenario requires that only the cluster namespace, not the master namespace, is pre-existing.
					// If primary followed "swapDbs" scenario but not backup, we'll throw an exception because the backup
					// databases won't correctly match up with the primary databases.
					s swapDbs=0
				}
				else {
					s errorCode=##class(%SYSTEM.Status).GetErrorCodes(status)
					if errorCode'=$$$ERRORCODE($$$CPFNameDoesNotExist) {
						// Attempt to get namespace returned error than "NameDoesNotExist"
						$$$SNDebugTrace("Attach 3b status:",status)
						throw ##class(%Exception.StatusException).CreateFromStatus(status)
					}
				}
			}
			if swapDbs {
				// When attaching backup in "swapDbs" scenario, make sure pre-existing cluster namespace's globals database
				// is actually mirrored with the master namespace's globals database on primary.
				s primaryMirrorDbName=$g(masterDbProperties("MirrorDBName"))
			}
			else {
				// When attaching backup, make sure pre-existing cluster namespace's globals database is actually
				// mirrored with cluster namespace's globals database on primary.
				s primaryMirrorDbName=$g(dbProperties("MirrorDBName"))
			}
			if 'swapDbs {
				s status=##class(Config.Databases).Get(clusterNamespaceProperties("Globals"),.backupDbProperties)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				s db=##class(SYS.Database).%OpenId($g(backupDbProperties("Directory")))
				if $d(db) {
					s backupMirrorDbName=db.MirrorDBName
					throw:backupMirrorDbName'=primaryMirrorDbName ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMDatabaseNotMirrorMatched,"Globals",$g(properties("Globals")),clusterNamespace,backupMirrorDbName,primaryMirrorDbName))
				}
			}
			else {
				s masterDbName=clusterNamespaceProperties("Globals"),masterRoutinesDbName=clusterNamespaceProperties("Routines")
				// Cluster namespace already exists, but we will map the master namespace, to be created below, to
				// its existing databases, and will create a new shard database:
				s status=..CreateOrReuseDatabase($$$SSShardDatabaseSubscript,$$$SSDefaultShardDatabase,.shardDbName,.dbProperties)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				s Properties("Globals")=shardDbName,Properties("Routines")=shardDbName
				s status=##class(Config.Namespaces).Modify(clusterNamespace,.Properties)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			}
		}

		// If attaching the backup failover member or DR async member of node 1, create master namespace and database,
		// if they don't already exist
		if pNodeType=$$$SSNodeTypeMirror&&(pMemberRole=$$$SSMemberRoleBackup||(pMemberRole=$$$SSMemberRoleDRAsync))&&(shardNumber=1)
		{
			s status=##class(Config.Namespaces).Get(masterNamespace,.properties)
			if status'=$$$OK {
				s errorCode=##class(%SYSTEM.Status).GetErrorCodes(status)
				if errorCode=$$$ERRORCODE($$$CPFNameDoesNotExist) {
					if 'swapDbs {
						// masterNamespace does not exist, create it
						// If a master database is specified, create it if it doesn't exist, else reuse existing.
						// Else, create one with default name, and specified path if specified, else default path.
						s status=..CreateOrReuseDatabase($$$SSMasterDatabaseSubscript,$$$SSDefaultDMDatabase,.masterDbName,.masterDbProperties)
						throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
						// If master namespace on primary member has separate routines database, then if specified, create
						// if doesn't exist, else reuse existing. Else, create one with default name and default path.
						if $g(masterRoutinesDbSettings)'="" {
							s status=..CreateOrReuseDatabase($$$SSMasterRoutinesDatabaseSubscript,$$$SSDefaultDMRoutinesDatabase,.masterRoutinesDbName,.masterRoutinesDbProperties)
							throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
						}
						else {
							s masterRoutinesDbName=masterDbName
						}
					}
					// Else we will use preexisting cluster namespace's databases as master globals and routines databases.
					// Create master namespace
					k Properties
					s Properties("Globals")=masterDbName,Properties("Routines")=masterRoutinesDbName
					s status=##class(Config.Namespaces).Create(masterNamespace,.Properties)
					throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
					// Enable interoperability, if it is enabled in master namespace on template node
					if masterEnableInterop {
						if (##class(%Library.EnsembleMgr).IsEnsembleInstalled()) {
							s status=##class(%EnsembleMgr).populateIsPrimary(.isPrimary)
							throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
							if isPrimary {
								s status=##class(%Library.EnsembleMgr).EnableNamespace(masterNamespace)
  								throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
							}
						}
					}
				}
				else {
					// Attempt to get namespace returned error than "NameDoesNotExist"
					$$$SNDebugTrace("Attach 3 status:",status)
					throw ##class(%Exception.StatusException).CreateFromStatus(status)
				}
			}
			// Else masterNamespace exists, simply use it as-is
			elseif $system.Mirror.IsMember()&&'$system.Mirror.IsPrimary() {
				// When attaching backup or DR async, make sure pre-existing master namespace's globals and routines databases
				// are actually mirrored with master namespace's globals and routines databases on primary
				s primaryMirrorDbName=$g(masterDbProperties("MirrorDBName"))
				s status=##class(Config.Databases).Get($g(properties("Globals")),.backupDbProperties)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				s db=##class(SYS.Database).%OpenId($g(backupDbProperties("Directory")))
				if $d(db) {
					s backupMirrorDbName=db.MirrorDBName
					throw:backupMirrorDbName'=primaryMirrorDbName ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMDatabaseNotMirrorMatched,"Globals",$g(properties("Globals")),masterNamespace,backupMirrorDbName,primaryMirrorDbName))
				}
				s:$d(masterRoutinesDbProperties("MirrorDBName")) primaryMirrorDbName=masterRoutinesDbProperties("MirrorDBName")
				s status=##class(Config.Databases).Get($g(properties("Routines")),.backupDbProperties)
				throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
				s db=##class(SYS.Database).%OpenId($g(backupDbProperties("Directory")))
				if $d(db) {
					s backupMirrorDbName=db.MirrorDBName
					throw:backupMirrorDbName'=primaryMirrorDbName ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SHMDatabaseNotMirrorMatched,"Routines",$g(masterRoutinesDbName),masterNamespace,backupMirrorDbName,primaryMirrorDbName))
				}
			}
		}
		
		// Set SQL settings to match those on template node
		s status=##class(Config.SQL).Modify(.sqlProperties)
		$$$SNDebugTrace("Attach modified SQL properties, status:",status)
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)

		// Enable sharding
		s status=$system.Sharding.EnableSharding(0,1,allowedIPs)
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		if pHostIPAddress="" {
			s myHost=$$getmyhostname^%SYS.SHARDSRV()
		}
		else {
			s status=$SYSTEM.Sharding.SetNodeIPAddress(pHostIPAddress)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
			s myHost=pHostIPAddress
		}
		s msg=$$$SSMsgCodeCompleteAttach_$lb(url("Namespace"),myHost,$$getmydefaultport^%SYS.SHARDSRV(),nodeType,
			$system.Mirror.MirrorName(),$piece($system,":",2),agentPort,($g(sslDirectory)'=""))
		d $$$SNCom.clisend(dev,msg)
		s reply=$$$SNCom.clirecv(dev)
		s status=$lg(reply)
		if status'=$$$OK {
			s maxNodes=0,errorCodes=$system.Status.GetErrorCodes(status)
			for errIdx=1:1 {
				s piece=$p(errorCodes,",",errIdx)
				q:piece=""
				s:piece=$$$SHMMaxNodes maxNodes=1
			}
			if maxNodes {
				s resetStatus=$$resetClusterNamespaceAndInitialized^%SYS.SHARDSRV(url("Namespace"))
				if resetStatus'=$$$OK {
					s status=##class(%SYSTEM.Status).AppendStatus(resetStatus,status)
				}
			}
			throw ##class(%Exception.StatusException).CreateFromStatus(status)		
		}
		// No need to send disconnect message, shard server automatically aborts after
		// processing MsgCodeCompleteAttach, so just close the device.
		d $$$SNCom.cliclose(dev)
		s $$$SSSysGlobal($$$SSShardingSubscript,$$$SSClusterNamespaceSubscript)=clusterNamespace
		if pNodeType=$$$SSNodeTypeMirror {
			if (pMemberRole=$$$SSMemberRoleBackup||(pMemberRole=$$$SSMemberRoleDRAsync))&&(shardNumber=1) {
				s $$$SSSysGlobal($$$SSShardingSubscript,$$$SSMasterNamespaceSubscript)=masterNamespace
			}
			elseif pMemberRole=$$$SSMemberRolePrimary {
				s shardNumber=+$g($$$SSShardLocalGlobal)
				if preexistingMirror {
					s status=##class(Config.Mirrors).Get($system.Mirror.MirrorName(),.properties)
					if status=$$$OK&&($g(properties("ArbiterNode"))'="") {
						s arbiterNode=properties("ArbiterNode")
						s arbiterIP=$p(arbiterNode,"|",1)
						s arbiterPort=$p(arbiterNode,"|",2)
						s $$$SSGlobal($$$SSShardsSubscript,shardNumber,$$$SSArbiterSubscript)=$lb(arbiterIP,arbiterPort)
					}
				}
				else {
					s arbiterIP=pArbiterIP,arbiterPort=pArbiterPort
				}
				if arbiterIP'="" {
					s $$$SSExtendedGlobal(clusterNamespace)($$$SSShardsSubscript,shardNumber,$$$SSArbiterSubscript)=$lb(arbiterIP,arbiterPort)
				}
			}
			if sslDirectory'=""&&'preexistingMirror {
				d setSSLDirectory^%SYS.SHARDSRV(sslDirectory)
			}
		}
	}
	catch ex {
		s status=ex.AsStatus()
	}
	if status=$$$OK {
		d setNodeInitialized^%SYS.SHARDSRV(1)
		if $g(%SNDatabasesNeedingCatchup)'=""&&($listvalid(%SNDatabasesNeedingCatchup)) {
			// Make a final attempt to catchup databases
			s catchupDbs=%SNDatabasesNeedingCatchup
			k %SNDatabasesNeedingCatchup
			for ii=1:1:$ll(catchupDbs) {
				d ..CatchupDBInternal($lg(catchupDbs,ii),,2)
			}
		}
		if $g(%SNDatabasesNeedingCatchup)'=""&&($listvalid(%SNDatabasesNeedingCatchup)) {
			if $ll(%SNDatabasesNeedingCatchup)>1 {
				s dbNames=$lg(%SNDatabasesNeedingCatchup,1)_" or "_$lg(%SNDatabasesNeedingCatchup,2)
			}
			else {
				s dbNames=$lg(%SNDatabasesNeedingCatchup)
			}
			s status=$$$ERROR($$$SHMCantCatchupDb,dbNames)
		}
	}
	lock:locked -$$$SSExtendedSysGlobal($$$SSShardingSubscript)#"I" // JMM1175=
	return status
}

ClassMethod SwapDatabases(pNamespace1 As %String, pNamespace2 As %String) As %Status [ Internal, Private ]
{
	s status=##class(Config.Namespaces).Get(pNamespace1,.properties1)
	return:status'=$$$OK status
	s status=##class(Config.Namespaces).Get(pNamespace2,.properties2)
	return:status'=$$$OK status
	s globals1=$g(properties1("Globals"))
	s routines1=$g(properties1("Routines"))
	s properties1("Globals")=properties2("Globals")
	s properties1("Routines")=properties2("Routines")
	s properties2("Globals")=globals1
	s properties2("Routines")=routines1
	s status=##class(Config.Namespaces).Modify(pNamespace1,.properties1)
	return:status'=$$$OK status
	s status=##class(Config.Namespaces).Modify(pNamespace2,.properties2)
	return status
}

ClassMethod CreateOrReuseDatabase(pDbNameSubscript As %String, pDbNameDefault As %String, ByRef pDbName As %String, ByRef pTemplateProperties) As %Status [ Internal, Private ]
{
	// Is database name specified?  If so, and it
	// exists, use it, else create
	s useExistingDatabase=0
	s pDbName=$g($$$SSSysGlobal($$$SSShardingSubscript,pDbNameSubscript))
	if pDbName="" {
		// Create a new database, named pDbNameDefault or the
		// first non-existent name pDbNameDefault_n where n is 1,2,3,...
		s pDbName=pDbNameDefault,dbNameSuffix=0,dbSpecified=0
	}
	else {
		s dbSpecified=1
	}
	s dbExists=0
	s baseDbName=pDbName
	do {
		s status=##class(Config.Databases).Get(pDbName,.properties)
		if status=$$$OK {
			if dbSpecified {
				s dbExists=1
				s db=##class(SYS.Database).%OpenId(properties("Directory"))
				if db.MirrorSetName="" {
					return $$$ERROR($$$SHMDatabaseNotMirrored,pDbName)
				}
			}
			else {
				s pDbName=baseDbName_$i(dbNameSuffix)
			}
		}
		else {
			s errorCode=##class(%SYSTEM.Status).GetErrorCodes(status)
			if errorCode'=$$$ERRORCODE($$$CPFNameDoesNotExist) {
				$$$SNDebugTrace("CreateOrReuseDatabase 1 status:",status)
				return status
			}
		}
	} while status=$$$OK&&'dbSpecified
	if 'dbExists {
		// Local setting of ^SYS("Sharding",pDbNameSubscript,"Path") overrides value copied from
		// template node, or default
		s path=$g($$$SSSysGlobal($$$SSShardingSubscript,pDbNameSubscript,$$$SSPathSubscript))
		s:path="" path=$g(pTemplateProperties("Directory"))
		s status=$$$OK
		if path="" {
			s path=$zu(12)_$zcvt(pDbName,"L")
		}
		s path=##class(%File).NormalizeDirectory(path)
		// If path doesn't already exist, create it. If it already exists and already
		// contains a iris.dat, throw exception.
		if '##class(%File).Exists(path) {
			s created=##class(%File).CreateDirectoryChain(path,.err)
			if 'created {
				s status=$$$ERROR($$$SHMCannotCreateDatabase,pDbName,path,err)
				return status
			}
		}
		elseif ##class(%File).Exists(path_"IRIS.DAT") {
			s status=$$$ERROR($$$SHMDatabaseFileExists,pDbName,path)
			return status
		}
		// Create the database with this path
		s mirrorSetName=$SYSTEM.Mirror.MirrorName()
		if mirrorSetName="" && $system.Mirror.IsMember() {
			s mirrorSetName=$g(pTemplateProperties("MirrorSetName"))
		}
		if mirrorSetName="" {
			s mirrorDbName=""
		}
		else {
			s mirrorDbName=$g(pTemplateProperties("MirrorDBName"))
			s:mirrorDbName="" mirrorDbName=pDbName
		}
		s pTemplateProperties("MirrorDBName")=mirrorDbName,pTemplateProperties("MirrorSetName")=mirrorSetName
		s db=##class(SYS.Database).%New()
		s db.Directory=path
		d setDatabaseProperties^%SYS.SHARDSRV(db,.pTemplateProperties)
		s status=db.%Save()
		if status'=$$$OK {
			return status
		}
		// Create config entry for the database
		s Properties("Directory")=path
		s status=##class(Config.Databases).Create(pDbName,.Properties)
		if status'=$$$OK {
			return status
		}
		// Create and store the mirror form of the database path
		// TBD: This code was adapted from old code for creating
		// the shard routine database, pre-USD.  It's not clear
		// what, if anything, was ever done with the variables set
		// in this next block of code.
		if $SYSTEM.Mirror.IsPrimary() {
			s mirrorDBInfo=$SYSTEM.Mirror.DBGetInfoByName(0,path)
			s database=$piece(mirrorDBInfo,"^",2)
			s mirrorName=$piece(mirrorDBInfo,"^",8)
			s mirrorDirectory=":mirror:"_mirrorName_":"_database
		}
		elseif mirrorDbName'="" {
			d ..CatchupDBInternal(pDbName,path)
		}
		if status'=$$$OK {
			$$$SNDebugTrace("CreateOrReuseDatabase 2 status:",status)
			return status
		}
	}
	return status
}

ClassMethod CatchupDBInternal(pDbName As %String, pPath As %String = "", pPass = 1) As %Status [ Internal, Private ]
{
	// Catchup the database if needed
	if pPass=1 {
		s limit=0
		s:$g(%SNCatchupLoopLimit1)'="" limit=%SNCatchupLoopLimit1
	}
	else {
		// pPass=2
		s limit=120
		s:$g(%SNCatchupLoopLimit2)'="" limit=%SNCatchupLoopLimit2 
	}		
	if limit=0 {
		// Don't try to catch up on this pass, we'll catchup this database on 2nd pass
		s %SNDatabasesNeedingCatchup=$g(%SNDatabasesNeedingCatchup)_$lb(pDbName)
	}
	if $g(pPath)="" {
		s status=##class(Config.Databases).Get(pDbName,.properties)
		return:status'=$$$OK status
		s pPath=$g(properties("Directory"))
	}
	for ii=1:1:limit {
		s db=##class(SYS.Database).%OpenId(pPath)
		if $d(db) {
			$$$SNDebugLog("Catchup iteration "_ii_" Db "_pDbName_" ROReasonCode: "_db.ROReasonCode_" InActiveMirror: "_db.InActiveMirror)
			if db.ROReasonCode=10  { // Mirrored DB needs to be caught up
				if ii=limit {
					$$$SNConsoleWarn("Could not catch up database "_pDbName_", manual catchup required")
					s %SNDatabasesNeedingCatchup=$g(%SNDatabasesNeedingCatchup)_$lb(pDbName)
					quit
				}
				$$$SNConsoleLog("Attempting to catch up database "_pDbName_", sfn #"_db.SFN)
				s res=##class(SYS.Mirror).CatchupDB($lb(db.SFN),,.errList)
				$$$SNDebugLog("CatchupDB for "_pDbName_" returned "_res_", failed sfn: "_$lg($g(errList)))
				if 'res&&($g(errList)'="") {
					$$$SNConsoleLog("Could not catch up database "_pDbName)
				}
			}
			else {
				$$$SNDebugLog("Quitting loop for pDbName "_pDbName_" at iteration "_ii)
				quit
			}
			h 1
			k db
		}
		else {
			$$$SNConsoleLog("Could not open database object for "_pDbName)
			if ii=limit {
				$$$SNConsoleWarn("Could not catch up database "_pDbName_", manual catchup required")
				s %SNDatabasesNeedingCatchup=$g(%SNDatabasesNeedingCatchup)_$lb(pDbName)
			}
		}
	}
	$$$SNDebugLog("CreateOrReuseDatabase After loop for pDbName "_pDbName_", ii: "_ii)
	return $$$OK
}

/// Catches up the database specified by pDbName.  Call this method if <method>AttachAsMirroredNode</method>
/// returns the error message "Cannot catch up database <i>dbname</i>, manual catchup required".
/// <p><b>Parameters:</b></p>
/// <dl>
/// <dt><i>pDbName</i></dt>
/// <dd>The name of the database to catch up.</dd>
/// </dl>
/// <p><b>Returns:</b>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.</dd>
/// </dl>
ClassMethod CatchupDB(pDbName As %String) As %Status
{
	new %SNDatabasesNeedingCatchup,$namespace
	s $namespace="%SYS"
	s status=..CatchupDBInternal(pDbName,,2)
	return:status'=$$$OK status
	if $g(%SNDatabasesNeedingCatchup)'="" {
		return $$$ERROR($$$SHMCantCatchupDb,pDbName)
	}
	return $$$OK
}

ClassMethod GetDbPropsForNamespace(pNamespace As %String, pDbNameSubscript As %String, pDbNameDefault As %String, ByRef pProperties, ByRef pNamespaceExists As %Boolean, ByRef pNamespaceIsInteropEnabled As %Boolean) As %Status [ Internal, Private ]
{
	k pProperties
	s pNamespaceIsInteropEnabled=0
	s status=##class(Config.Namespaces).Get(pNamespace,.properties)
	if status'=$$$OK {
		s errorCode=##class(%SYSTEM.Status).GetErrorCodes(status)
		if errorCode'=$$$ERRORCODE($$$CPFNameDoesNotExist) {
			return status
		}
		else {
			s pNamespaceExists=0
			s dbName=$g($$$SSSysGlobal($$$SSShardingSubscript,pDbNameSubscript))
			if dbName="" {
				return $$$OK
			}
		}
	}
	else {
		s pNamespaceExists=1
		s pNamespaceIsInteropEnabled=##class(%Library.EnsembleMgr).IsEnsembleNamespace(pNamespace)
		s dbName=$g(properties("Globals"))
		return:dbName="" $$$OK
	}
	s status=##class(Config.Databases).Get(dbName,.properties)
	if status'=$$$OK {
		s errorCode=##class(%SYSTEM.Status).GetErrorCodes(status)
		if errorCode'=$$$ERRORCODE($$$CPFNameDoesNotExist) {
			return status
		}
		else {
			// Database doesn't exist
			return $$$OK
		}
	}
	s dir=properties("Directory")
	d getDatabaseProperties^%SYS.SHARDSRV(dir,.pProperties)
	return $$$OK
}

/// Gets the name of the cluster namespace on the current InterSystems IRIS instance.
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Name of the cluster namespace, or empty string if this instance is not a node in a cluster.</dd>
/// </dl>
ClassMethod ClusterNamespace() As %String
{
	return $$getClusterNamespace^%SYS.SHARDSRV()
}

/// Lists the nodes of the cluster to which the current InterSystems IRIS instance belongs, 
/// to the console or to a specified output file.
/// <p>The list contains a row for each node, with information in columns under the following headings:</p>
/// <ul>
/// <li>NodeId - a numeric id.  For data nodes, this is identical to the shard number.</li>
/// <li>NodeType - "Data" or "Compute".</li>
/// <li>DataNodeId - for compute nodes only, the id of the corresponding data node.</li>
/// <li>Host - the hostname or IP address of the machine hosting the node's InterSystems IRIS instance.</li>
/// <li>Port - the default port (Super Server port) of the InterSystems IRIS instance.</li>
/// <li>Mirror - the mirror name, if the node is mirrored.</li>
/// <li>Failover - for mirrored nodes only, the type of failover member, either "Primary" or "Backup".</li>
/// <li>VIP - for mirrored nodes only, the VIP, if one is configured. </li>
/// </ul>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>pOutputFile</i></dt>
/// <dd>The pathname of a file to which output is written. Default: Prints output to the console.</dd>
/// </dl>
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.</dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>Nodes which are pending removal, because they have been detached but the cluster has not yet been 
/// rebalanced to moved sharded data from them to other shards, are listed 
/// with their shard number in brackets and followed by two asterisks, for example "[25**]".</li>
/// </ul>
/// </dl>
ClassMethod ListNodes(pOutputFile As %String = "") As %Status
{
	return $$listNodes^%SYS.SHARDSRV(pOutputFile)
}

/// Retrieves an overview of the metadata of the cluster to which the current InterSystems IRIS instance 
/// belongs. 
/// <p>The metadata is returned in an array, passed by reference, under the following subscripts:</p>
/// <ul>
/// <li>ClusterNamespace - the name of the cluster namespace, visible on all nodes.</li>
/// <li>MasterNamespace - the name of the master namespace on node 1.</li>
/// <li>MasterGlobalsDatabase - the name of the globals database of the master namespace.</li>
/// <li>MasterRoutinesDatabase - the name of the routines database of the master namespace.</li>
/// <li>Node - information specific to individual nodes, stored under two additional subscripts: the
/// node's numeric id (with ":Primary" or ":Backup" appended for mirrored nodes), and one of the following:
/// <ul>
/// <li>NodeType - "Data" or "Compute".</li>
/// <li>DataNodeId - for compute nodes only, the id of the corresponding data node.</li>
/// <li>ShardDatabase - for data nodes only, the name of the database containing this node's portion of sharded data.</li>
/// <li>Host  - the hostname or IP address of the machine hosting the node's InterSystems IRIS instance.</li>
/// <li>SuperServerPort - the default port (Super Server port) of the InterSystems IRIS instance.</li>
/// <li>WebServerPort - the web server port of the InterSystems IRIS instance.</li>
/// <li>IRISVersion - the InterSystems IRIS version number.</li>
/// <li>ShardingVersion - the sharding manager version number.</li>
/// </ul>
/// </li> 
/// </ul>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>pMetadata</i></dt>
/// <dd>Array in which metadata is returned, passed by reference.</dd>
/// </dl>
/// <p><b>Returns:</b></p>
/// <dl>
/// <dt></dt>
/// <dd>Status code reporting success or failure of this API call.</dd>
/// </dl>
ClassMethod GetMetadata(ByRef pMetadata) As %Status
{
	return $$getMetadata^%SYS.SHARDSRV(.pMetadata)
}

/// Create a mirror member on the designated instance<br>
/// <b>pMirrorSetName</b>  Mirror Set name<br>
/// <b>pPrimaryName</b>    Primary member name<br>
/// <b>pPrimaryIP</b>      Primary member IP address<br>
/// <b>pBackupName</b>     Backup member name<br>
/// <b>pBackupIP</b>       Backup member IP address<br>
/// <b>pAgentPort</b>      ISC Agent Port<br>
/// <b>pNodeType</b>       "primary" | "backup" | "async"<br>
/// <b>pInstance</b>       Instance name<br>
/// <b>pArbiterIP</b>      Arbiter Node IP address<br>
/// <b>pArbiterPort</b>    Arbiter Node port number<br>
/// <b>pSSLdir</b>         SSL/TLS keys directory<br>
ClassMethod CreateMirror(pMirrorSetName As %String = "", pPrimaryName As %String = "", pPrimaryIP As %String = "", pBackupName As %String = "", pBackupIP As %String = "", pAgentPort As %Integer = "", pNodeType As %String = "", pInstance As %String = "", pArbiterIP As %String = "", pArbiterPort As %Integer = 0, pSSLdir As %String = "") As %String [ Internal, Private ]
{
  #dim tSC As %Status = $$$OK
  #dim tBool As %Boolean = $$$OK
  #dim tObj As %ObjectHandle

  // validate
  if pMirrorSetName'="" {
  	Set tBool = ($LENGTH(pMirrorSetName) <= 15) && (pMirrorSetName?.AN)
  	Return:'tBool $$$ERROR($$$InvalidIdentifierFormat, "Invalid mirror set name: "_pMirrorSetName)
  }
  if pPrimaryIP'="" {
  	Set tBool = $System.INetInfo.CheckAddressExist(pPrimaryIP)
  	Return:'tBool $$$ERROR($$$GeneralError, "No such address: "_pPrimaryIP)
  	Set tSC = ##class(SYS.MirrorConfiguration).IsIPFormatValid(pPrimaryIP, .type)
  	Return:$$$ISERR(tSC) tSC
  }
  if pBackupIP'="" {
  	Set tSC = $System.INetInfo.CheckAddressExist(pBackupIP)
  	Return:'tBool $$$ERROR($$$GeneralError, "No such address: "_pBackupIP)
  	Set tSC = ##class(SYS.MirrorConfiguration).IsIPFormatValid(pBackupIP, .type)
  	Return:$$$ISERR(tSC) tSC
  }
  if pPrimaryName'="" {
  	Set tSC = ##class(Config.MirrorMember).ValidateMemberName(pPrimaryName)
  	Return:$$$ISERR(tSC) tSC
  }
  if pBackupName'="" {
  	Set tSC = ##class(Config.MirrorMember).ValidateMemberName(pBackupName)
  	Return:$$$ISERR(tSC) tSC
  }
  if pSSLdir'="" {
	  s pSSLdir=##class(%File).NormalizeDirectory(pSSLdir)
	  if '##class(%File).Exists(pSSLdir) {
		  Return $$$ERROR($$$GeneralError, "No such directory path: "_pSSLdir)
	  }
  }
  // enable mirroring
  Set tBool = ##Class(Security.Services).Exists("%Service_Mirror", .tService, .tSC)
  Return:$$$ISERR(tSC) tSC
  Return:'tBool $$$ERROR($$$GeneralError, "Mirror service not found")
  Set tService.Enabled = 1
  Set tSC = tService.%Save()
  Return:$$$ISERR(tSC) tSC
  Set tObj = ##class(Config.Mirrors).Open(pMirrorSetName)
  Return:$ISOBJECT(tObj) $$$ERROR($$$MirrorSetNameNotUnique, "Mirror already exists: "_pMirrorSetName)

  // configure SSL/TLS
  #dim tMirrorInfo As %String
  Set tMirrorInfo("UseSSL") = (pSSLdir'="")
  // Don't specify agent port for backup member here, let the mirror methods use the
  // value from ##class(SYS.MirrorConfiguration).GetAgentPort()
  Set:pNodeType="primary" tMirrorInfo("AgentPort") = pAgentPort
  #dim tSSLInfo As %String
  // 1st choice for file names to look for:
  // names that correspond to the subscripts in tSSLInfo.
  // If those don't exist, use ICM names.
  // If those don't exist, use Kubernetes names.
  s caFile=pSSLdir_"CAFile.pem"
  if '##class(%File).Exists(caFile) {
	  s caFile=pSSLdir_"ca.pem"
  }
  s certificateFile=pSSLdir_"CertificateFile.pem"
  if '##class(%File).Exists(certificateFile) {
	  s certificateFile=pSSLdir_"server-cert.pem"
	  if '##class(%File).Exists(certificateFile) {
		s certificateFile=pSSLdir_"tls.crt"
	  }
  }
  s privateKeyFile=pSSLdir_"PrivateKeyFile.pem"
  if '##class(%File).Exists(privateKeyFile) {
	  s privateKeyFile=pSSLdir_"server-key.pem"
	  if '##class(%File).Exists(privateKeyFile) {
		s privateKeyFile=pSSLdir_"tls.key"
	  }
  }
  Set tSSLInfo("CAFile") = caFile
  Set tSSLInfo("CertificateFile") = certificateFile
  Set tSSLInfo("PrivateKeyFile") = privateKeyFile
  Set tSSLInfo("PrivateKeyType") = 2
  Set tSSLInfo("CipherList") = "ALL:!aNULL:!eNULL:!EXP:!SSLv2"
  Set tSSLInfo("Ciphersuites") = $$$TLSDEFAULTCIPHERSUITES
  #;SML2808 Set tSSLInfo("TLSMinVersion") = 0
  #;SML2808 Set tSSLInfo("TLSMaxVersion") = 0

  // configure Arbiter
  If (pArbiterIP '= "" && pArbiterPort) {
    Set tMirrorInfo("ArbiterNode") = pArbiterIP_"|"_pArbiterPort
  }

  If (pNodeType = "primary") { // create mirror
      Set tMirrorInfo("ECPAddress") = pPrimaryIP
      Set tMirrorInfo("MemberType") = 0 // failover
      Set tSC = ##class(SYS.Mirror).CreateNewMirrorSet(pMirrorSetName,pPrimaryName,.tMirrorInfo,.tSSLInfo)
      Return:$$$ISERR(tSC) tSC
      // wait for mirror set creation before proceeding
      For i=1:1:60 {
        Set tObj = ##class(SYS.MirrorConfiguration).RetrieveMirrorConfig(pMirrorSetName,pPrimaryIP,pAgentPort,pInstance,.tSC)
        Quit:$ISOBJECT(tObj)
        Hang 1
      }
      Return:$$$ISERR(tSC) tSC
      Return:'$ISOBJECT(tObj) $$$ERROR($$$FailedToRetrieveMirrorConfig, "Timed out retrieving mirror config for "_pMirrorSetName)
  } Else { // join existing mirror
      Set tObj = ##class(SYS.MirrorConfiguration).RetrieveMirrorConfig(pMirrorSetName,pPrimaryIP,pAgentPort,pInstance,.tSC)
      Return:$$$ISERR(tSC) tSC
      Return:'$ISOBJECT(tObj) $$$ERROR($$$FailedToRetrieveMirrorConfig, pMirrorSetName)
      Set tMirrorInfo("ECPAddress") = pBackupIP
    If (pNodeType = "backup") {
        Set tMirrorInfo("MemberType") = 0 // failover
        Set tSC = ##class(SYS.Mirror).JoinMirrorAsFailoverMember(pMirrorSetName,pBackupName,pInstance,pPrimaryIP,pAgentPort,.tMirrorInfo,.tSSLInfo)
        Return:$$$ISERR(tSC) tSC
    } ElseIf (pNodeType = "async") {
        Set tMirrorInfo("MemberType") = 2 // Async
      #dim tAsyncMemberType As %Integer = 0 // 0:Disaster Recovery 1:Read-Only Reporting 2:Read-Write Reporting
        Set tSC = ##class(SYS.Mirror).JoinMirrorAsAsyncMember(pMirrorSetName,pBackupName,pInstance,pPrimaryIP,pAgentPort,tAsyncMemberType,.tMirrorInfo,.tSSLInfo)
        Return:$$$ISERR(tSC) tSC
    } Else {
      Return $$$ERROR($$$GeneralError, "Invalid node type: "_pNodeType)
    }
  }
  Return tSC
}

ClassMethod IsNodeReady(pClusterURL As %String = "") As %Status
{
	new %SNAllowConnectToBackupFailoverMember,%SNInIsNodeReady
	s %SNAllowConnectToBackupFailoverMember=1,%SNInIsNodeReady=1
	try {
		if pClusterURL'="" {
			s status=$$parseClusterURL^%SYS.SHARDSRV(pClusterURL,.url)
			throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		}
		// If no Cluster URL is specified, or specified URL identifies the current node, determine whether
		// current node is initialized.
		if pClusterURL=""||($$hostsEqual^%SYS.SHARDSRV(url("Host"),$$getmyhostname^%SYS.SHARDSRV())&&(url("Port")=$$getmydefaultport^%SYS.SHARDSRV()))
		{
			if $$getNodeInitialized^%SYS.SHARDSRV()=1 {
				return $$$OK
			}
			else {
				return $$$ERROR($$$SHMNodeNotInitialized)
			}
		}
		// Else try to connect to specified cluster node and determine whether it is initialized.
		s status=$$connect^%SYS.SHARDSRV(.dev,url("Host"),url("Port"),url("Namespace"),$$$SSTCPMessaging,0,,1,1)
		s:status=$$$OK connected=1
		throw:status'=$$$OK ##class(%Exception.StatusException).CreateFromStatus(status)
		s msg=$$$SSMsgCodeIsNodeReady
		d $$$SNCom.clisend(dev,msg)
		s reply=$$$SNCom.clirecv(dev)
		s status=$lg(reply)
	}
	catch ex {
		s status=ex.AsStatus()
	}
	if +$g(connected) {
		try {
			d disconnect^%SYS.SHARDSRV(dev)
		}
		catch ex {
			// TBD: Do anything here?
		}
	}
	return status
}

/// Detaches the current InterSystems IRIS instance from the cluster to which it is currently attached.  This removes 
/// the instance from the cluster's set of nodes.
/// <p>This API call can be used to detach a data node (either mirrored on non-mirrored) or a compute node.
/// <p>If the current instance is a data node, and any sharded tables exist, the instance is not immediately detached,
/// but is flagged for pending removal.  In that case, the next call to the <method>Rebalance</method> method of <class>%SYSTEM.Sharding</class> moves any sharded data
/// from this node to other nodes of the cluster, and completes the process of detaching this instance.  Node 1 of a cluster may not be detached.
/// <p>If the current instance is a compute node, it is always immediately detached.
/// <p>Calling <b>Detach</b> on either failover member of a mirrored data node detaches both failover members
/// <p>Detaching a data node automatically detaches any compute nodes that are associated with that data node.
/// This method returns an error in any of the following cases:
/// <ul><dl>
/// <li>The current InterSystems IRIS instance is not a node of a sharded cluster.
/// <li>The current instance is node 1 of a sharded cluster.
/// </ul>
/// <p><b>Returns:</b>
/// <dd>Status code reporting success or failure of this API call.<br>
/// </dd>
/// <p><b>Notes:</b>
/// <ul>
/// <li>Detaching a node removes mappings that were created when the node was attached.  It does not remove the 
/// cluster namespace, but causes that namespace to no longer serve as a cluster namespace.
/// If the instance is mirrored, detaching does not remove the instance from the mirror.
/// <li>When a data node is flagged for pending removal, due to calling <b>Detach</b> while sharded tables exist,
/// the pending removal can be cancelled by calling <method>AttachAsDataNode</method> (for a non-mirrored data node), 
/// <method>AttachAsMirroredNode</method> (for a mirrored data node), or <method>AttachAsComputeNode</method> (for a compute
/// node).  Call <method>ListNodes</method> to determine whether a node is currently flagged for pending removal.
/// <li>When a node is detached, the node numbers of any higher-numbered nodes are decremented to maintain an unbroken
/// numeric sequence.  If the node is flagged for pending removal, the numbers of higher-numbered nodes aren't changed
/// until the process of detaching the node is completed during the next call to the <class>%SYSTEM.Sharding</class> 
/// <b>Rebalance</b> method.
/// </ul>
ClassMethod Detach() As %Status
{
	s clusterNamespace=$$getClusterNamespace^%SYS.SHARDSRV()
	return:clusterNamespace="" $$$ERROR($$$SHMNotClusterNode)
	new $namespace
	s $namespace=clusterNamespace
	s myShardNumber=+$g($$$SSShardLocalGlobal)
	if myShardNumber=1 {
		return $$$ERROR($$$SHMCannotDetachNode1)
	}
	if $system.Mirror.IsBackup() {
		s $$$SNMessagingType=$$$SSTCPMessaging
	}
	s command=##class(%BigData.ShardingManagerCommand).%New()
	d command.%SetMsgCode($$$SSMsgCodeDetach)
	d command.%SetShardNumber(-1)
	s shard=$g($$$SSGlobal($$$SSShardsSubscript,+$g($$$SSShardLocalGlobal)))
	// Shard may have been pending removal, and, if rebalancing is in progress, may have
	// been cleaned up since we entered this call
	if shard="" || ($g($$$SSShardLocalGlobal)="") {
		return $$$ERROR($$$SHMNotClusterNode)
	}
	d command.%SetMessage(shard)
	s status=##class(%BigData.ShardingManager).%ExecCommand(command)
	// If node has actually been removed from cluster (as opposed to just flagged for pending removal), clean up connections,
	// so we'll start fresh if we try to re-attach in this same job
	if status=$$$OK && '$d($$$SSExtendedGlobal(clusterNamespace)) {
		$$$SSForceReconnectAllShards
		k %SNCom
		s $SYSTEM.Context.SN().com=##class(%BigData.TCPMessaging).%New("")
	}
	return status
}

}
