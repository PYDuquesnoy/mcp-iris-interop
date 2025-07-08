/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// Zen application intended for System Management Portal use only.
/// This class contains generic styles used by the SMP system wide. Change with caution.
Class %CSP.UI.Portal.Application Extends %CSP.Portal.Application [ System = 4 ]
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "System Management Portal";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// This Style block contains application-wide CSS style definitions.
XData Style
{
<style type="text/css">
/* @doc="label style for for Zen control 'button' in this application." */
.button {
	margin-left: 2px;
}
/* @doc="error note style used in idRespond" */
.errorNote {
	background: #FFFFFF;
	border: 1px solid #DA4848; /* red */
	border-radius: 4px;
	color: #DA4848;
	font-size: 12px;
	font-weight: bold;
	padding: 10px;
	text-align: left;
	display:inline-block;
}
/* @doc="regular note style used in idRespond" */
.note {
	background: #FFFFFF;
	border: 1px solid #CBCBCB;
	border-radius: 4px;
	color: #000000;
	font-size: 12px;
	font-weight: bold;
	padding: 10px;
	text-align: left;
	display:inline-block;
}
.successNote {
	background: #FFFFFF;
	border: 1px solid #94BABA; /* green */
	border-radius: 4px;
	color: #52B012;
	font-size: 12px;
	font-weight: bold;
	padding: 10px;
	text-align: left;
	display:inline-block;
}
/* @doc="generic label style used for Zen control 'label' in this application" */
.zenLabel {
	color: #000000;
	font-size: 12px;
	font-weight: 600;
	text-align: left;
}
/* @doc="generic hint style used for Zen control 'hint' in this application" */
.zenHint {
	color:#717171;
	font-size:12px;	
}
/* @doc="style for for links in forms in this application." */
.smpLink a.link {
	text-decoration:underline;
	font-weight:normal;
}
</style>
}

/// Provide finder contents for the System Config pages.
ClassMethod GetSystemConfigArray(Output pData) As %Status
{
	Set $ZT="Error"
	Set tNoDBSecurity = '$System.Security.Check("%DB_IRISSYS","READ,WRITE")
	Set tAdmin = ..CheckSecurity("%Admin_Manage")
	Set tAdminDisabled = ('tAdmin||tNoDBSecurity)
	Set tSecure = ..CheckSecurity("%Admin_Secure")
	Set tSecureDisabled = ('tSecure||tNoDBSecurity)
	Set lblNoPriv = $$$TextHTML("You do not have privilege to view this page.","%Utility")

	//Set pMetaData = $LB("name","title","link","disabled","icon","description")
 
 	#; Configuration options
	Set pData($i(n1)) = $LB($$$Text("Configuration"),$S(tAdminDisabled:lblNoPriv,1:$$$Text("Perform various actions related to system setup and configuration.")),,tAdminDisabled,..Link("portal/database_48.gif"))
	Set pData(n1,$i(n2)) = $LB($$$Text("System Configuration"),,,tAdminDisabled,..Link("portal/database_48.gif"))

	If tAdmin = 1 Do ..GetConfigurationArray(n1,n2,.pData)

  	Set n1 = $i(n1)
  	Set n2 = 0 	 

  	#; Security options
 	Set pData(n1) = $LB($$$Text("Security"),$S(tNoDBSecurity:lblNoPriv,1:$$$Text("Manage system security definitions.")),,tNoDBSecurity,..Link("portal/security_48.gif"))
  	Set pData(n1,$i(n2)) = $LB($$$Text("Users"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Users.zen"),tNoDBSecurity,..Link("portal/user_id_48.gif"),$$$Text("View, add, or edit user definitions."))

 	Do ..GetSecurityArray(n1,n2,.pData)

  	Set n1 = $i(n1) 
  	Set n2 = 0
	Set pData(n1) = $LB($$$Text("Licensing"),$S(tAdminDisabled:lblNoPriv,1:$$$Text("View and configure licensing information.")),,tAdminDisabled,..Link("portal/keys_48.gif"))
	Set pData(n1,$i(n2)) = $LB($$$Text("License Key"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.License.Key.zen"),,..Link("portal/keys_48.gif"),$$$Text("View license key information or Activate a new license key."))
	Set pData(n1,$i(n2)) = $LB($$$Text("License Servers"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.LicenseServers.zen"),,..Link("portal/keys_level_48.gif"),$$$Text("View and edit license server address and port."))

 	#; Encryption options
  	Set n1 = $i(n1)
  	Set n2 = 0
  	Set tLinkTitle = $Case(tSecureDisabled,0:$$$Text("Manage encrypted database settings."),:lblNoPriv)
	Set pData(n1) = $LB($$$Text("Encryption"),tLinkTitle,,tSecureDisabled,..Link("portal/encrypt_48.gif"))
	Set pData(n1,$i(n2)) = $LB($$$Text("Create New Encryption Key File"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.EncryptionCreate.zen"),tNoDBSecurity,..Link("portal/keys_48.gif"),$$$Text("Create new encryption key and key file."))
	Set pData(n1,$i(n2)) = $LB($$$Text("Manage Encryption Key File"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.EncryptionManage.zen"),tNoDBSecurity,..Link("portal/keys_48.gif"),$$$Text("Manage existing encryption key file."))
	Set pData(n1,$i(n2)) = $LB($$$Text("Database Encryption"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.EncryptionDatabase.zen"),tNoDBSecurity,..Link("portal/keys_48.gif"),$$$Text("Activate or Deactivate database encryption key, or configure startup options."))
	Set pData(n1,$i(n2)) = $LB($$$Text("Data Element Encryption"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.EncryptionManaged.zen"),tNoDBSecurity,..Link("portal/keys_48.gif"),$$$Text("Activate or Deactivate data element encryption keys for applications."))

	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit 0
}

ClassMethod GetSystemProviderArray(Output pData) As %Status
{
	Set $ZT="Error"
	If $namespace '= "%SYS" Set $Namespace = "%SYS"
	Set tNoDBSecurity = '$System.Security.Check("%DB_IRISSYS","READ,WRITE")
	Set tAdmin = ..CheckSecurity("%Admin_Manage")
	Set tAdminDisabled = ('tAdmin||tNoDBSecurity)
	Set tSecure = ..CheckSecurity("%Admin_Secure")
	Set tSecureDisabled = ('tSecure||tNoDBSecurity)
	Set lblNoPriv = $$$TextHTML("You do not have privilege to view this page.","%Utility")

	Set n1 = $i(n1)  	
	Set pData(n1) = $LB($$$Text("Defaults"),$S(tSecureDisabled:lblNoPriv,tAdminDisabled:lblNoPriv,1:$$$Text("View or edit Provider Defaults.")),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Default.zen"),(tSecureDisabled || tAdminDisabled),..Link("portal/gear_48.gif"),$$$Text("View or edit Provider Default settings."))
	Set n1 = $i(n1)  	
	Set pData(n1) = $LB($$$Text("Kits"),$S(tSecureDisabled:lblNoPriv,tAdminDisabled:lblNoPriv,1:$$$Text("View or edit Provider Kits.")),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Kits.zen"),(tSecureDisabled || tAdminDisabled),..Link("portal/gear_48.gif"),$$$Text("View or edit Provider Kits settings."))
	Set n1 = $i(n1)  	
	Set pData(n1) = $LB($$$Text("Manifests"),$S(tSecureDisabled:lblNoPriv,tAdminDisabled:lblNoPriv,1:$$$Text("View or edit Provider Manifests.")),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Manifests.zen"),(tSecureDisabled || tAdminDisabled),..Link("portal/gear_48.gif"),$$$Text("View or edit Provider Manifests settings."))
	Set n1 = $i(n1)  	
	Set pData(n1) = $LB($$$Text("Installs"),$S(tSecureDisabled:lblNoPriv,tAdminDisabled:lblNoPriv,1:$$$Text("View or edit Provider Installs.")),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Installs.zen"),(tSecureDisabled || tAdminDisabled),..Link("portal/gear_48.gif"),$$$Text("View or edit Provider Installs settings."))
	Set n1 = $i(n1)  	
	Set pData(n1) = $LB($$$Text("Machines"),$S(tSecureDisabled:lblNoPriv,tAdminDisabled:lblNoPriv,1:$$$Text("View or edit Provider Machines.")),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Machines.zen"),(tSecureDisabled || tAdminDisabled),..Link("portal/gear_48.gif"),$$$Text("View or edit Provider Machines settings."))
	Set n1 = $i(n1)  	
	Set pData(n1) = $LB($$$Text("Instances"),$S(tSecureDisabled:lblNoPriv,tAdminDisabled:lblNoPriv,1:$$$Text("View or edit Provider Instances.")),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Instances.zen"),(tSecureDisabled || tAdminDisabled),..Link("portal/gear_48.gif"),$$$Text("View or edit Provider Instances settings."))
	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit 0
}

/// This method is called only when user has %Admin_Manage priviledge <br>
/// with a few exceptions that require %Admin_Secure
ClassMethod GetConfigurationArray(n1, n2, Output pData) As %Status
{
	Set $ZT="Error"
	Set tSecure = ..CheckSecurity("%Admin_Secure")
	Set lblNoPriv = $$$TextHTML("You do not have privilege to view this page.","%Utility")
	#; We put the first entry in main method so that the child is not null (even for disabled menu the ">>" can be shown)
	#; Set pData(n1,$i(n2)) = $LB($$$Text("System Configuration"),,,,..Link("portal/database_48.gif"))	
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Memory and Startup"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.MemoryStartup.zen"),,..Link("portal/baud_48.gif"),$$$Text("View or edit system memory and start up settings."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Namespaces"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Namespaces.zen"),,..Link("portal/table_properties_48.gif"),$$$Text("View or edit namespaces."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Local Databases"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Databases.zen"),,..Link("portal/database_48.gif"),$$$Text("View or edit local databases."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Remote Databases"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.RemoteDatabases.zen"),,..Link("portal/database_level_48.gif"),$$$Text("View or edit remote databases."))

	Set tHasShardingLicense = $$Sharding^%SYS.LICENSE()
	Set tLinkTitle = $S(tHasShardingLicense'=1:$$$Text("Sharding is unavailable for current license."),1:"")
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Sharding"),tLinkTitle,,'tHasShardingLicense,..Link("portal/database_level_48.gif"))

	If tSecure && $System.Security.Check("%DB_IRISSYS","READ,WRITE") {
		Set tIsShardingEnabled = ##class(%CSP.UI.Portal.Sharding.Utils).IsShardingEnabled(.pService)
	} Else {
		Set tIsShardingEnabled = 0
	}
	
	If tHasShardingLicense = 1 {
		Set tLinkTitle = $S(tIsShardingEnabled:$$$Text("Sharding is already enabled."),1:$$$Text("Click to enable Sharding and ECP services."))
	}
	Set n4 = 0
	Set pData(n1,n2,n3,$i(n4)) = $LB($$$Text("Enable Sharding"),tLinkTitle,"zenPage.enableSharding();",tIsShardingEnabled,..Link("portal/socket_48.gif"),$$$Text("Select this option to enable the Sharding and ECP Services in order to configure sharding."))
	Set pData(n1,n2,n3,$i(n4)) = $LB($$$Text("Configure Node-Level"),$$$Text("Configure node-level clusters"),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Sharding.NodelevelConfig.zen"),'tIsShardingEnabled,..Link("portal/socket_48.gif"),$$$Text("Select this option to configure this instance as part of a node-level sharded cluster."))
	Set pData(n1,n2,n3,$i(n4)) = $LB($$$Text("Configure Namespace-Level"),$$$Text("Advanced namespace-level configuration"),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Sharding.Configuration.zen"),'tIsShardingEnabled,..Link("portal/socket_48.gif"),$$$Text("Select this option for advanced namespace-level sharded cluster configuration."))

	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Archive Targets"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Archives.zen"),,..Link("portal/list_48.gif"),$$$Text("View or edit archive settings."))
	Set tDisabled = '..CheckSecurity("%Admin_Journal")
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Journal Settings"),$S(tDisabled:lblNoPriv,1:""),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Journal.zen"),tDisabled,..Link("portal/list_48.gif"),$$$Text("View or edit journal settings."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("WQM Categories"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.WQMCategories.zen"),,..Link("portal/iris_config_48.gif"),$$$Text("Configure work queue manager categories."))
	#; MNF-001 Enhance Log Daemon API
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Log Daemon Configuration"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.LogDaemon.zen"),,..Link("portal/report_config_48.gif"),$$$Text("Configure the log daemon for this instance."))

	Set pData(n1,$i(n2)) = $LB($$$Text("Connectivity"),,,,..Link("portal/wan_48.gif"))
	Set n3 = 0
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("ECP Settings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ECP.zen"),,..Link("portal/wan_48.gif"),$$$Text("Configure ECP settings."))	

	If $zversion(n1) '= 1 {
		#; Show the following options if OS is not VMS:
		Set pData(n1,n2,$i(n3)) = $LB($$$Text("SQL Gateway Connections"),,..Link("/csp/sys/mgr/UtilSqlGateways.csp?Recent=1"),,..Link("portal/gateway_48.gif"),$$$Text("Set up and configure SQL Gateway connections."))
		Set pData(n1,n2,$i(n3)) = $LB($$$Text("External Language Servers"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ExternalLanguageServers.zen"),,..Link("portal/gateway_48.gif"),$$$Text("Configure Object Gateway Server definitions."))
	}
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Cluster Settings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.Cluster.zen"),,..Link("portal/cluster_48.gif"),$$$Text("View or edit cluster settings."))

	Set pData(n1,$i(n2)) = $LB($$$Text("Mirror Settings"),,,,..Link("portal/socket_48.gif"),$$$Text("Configure mirror on this system."))
	Set n3 = 0
	Set tIsMirrorServiceEnabled = ..EvaluateCondition("$$IsMirrorServiceEnabled^MIRRORCTL()",.tError)
	Set tDisabled = $S(tError="":tIsMirrorServiceEnabled,1:1)
	Set tLinkTitle = $S(tIsMirrorServiceEnabled=1:$$$TextHTML("Mirror service is already enabled."),1:$$$TextHTML("Click to enable the mirror service."))
	If tError '= "" Set tLinkTitle = tError
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Enable Mirror Service"),tLinkTitle,"zenPage.enableMirroring();",tDisabled,..Link("portal/socket_48.gif"),$$$Text("Select this option to enable the Mirror Service in order to configure mirroring."))
	Set tDisabled = ..EvaluateCondition("'##class(SYS.MirrorConfiguration).EnableMirrorMenu(1)",.tError)
	Set tLinkTitle = $$$TextHTML("This option is enabled when a mirror is not defined and this system is not an Async member.")
	If tError '= "" Set tDisabled = 1,tLinkTitle = tError
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Create a Mirror"),tLinkTitle,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Mirror.Create.zen"),tDisabled,..Link("portal/socket_48.gif"),$$$Text("Set up and configure mirror definition."))
	Set tDisabled = ..EvaluateCondition("'##class(SYS.MirrorConfiguration).EnableMirrorMenu(6)",.tError)
	Set tLinkTitle = $$$TextHTML("This option is enabled when a mirror is defined and this system is not an Async member.")
	If tError '= "" Set tDisabled = 1,tLinkTitle = tError
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Edit Mirror"),tLinkTitle,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Mirror.EditFailover.zen"),tDisabled,..Link("portal/socket_48.gif"),$$$Text("Edit existing mirror definition."))
	Set tDisabled = ..EvaluateCondition("'##class(SYS.MirrorConfiguration).EnableMirrorMenu(7)",.tError)
	Set tLinkTitle = $$$TextHTML("This option is enabled when this system is configured as an Async member.")
	If tError '= "" Set tDisabled = 1,tLinkTitle = tError
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Edit Async"),tLinkTitle,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Mirror.EditAsync.zen"),tDisabled,..Link("portal/socket_48.gif"),$$$Text("Edit Async configurations."))
	Set tDisabled = ..EvaluateCondition("'##class(SYS.MirrorConfiguration).EnableMirrorMenu(2)",.tError)
	Set tLinkTitle = $$$TextHTML(" This option is enabled when a mirror is not defined and this system is not an Async member.")
	If tError '= "" Set tDisabled = 1,tLinkTitle = tError
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Join as Failover"),tLinkTitle,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Mirror.JoinFailover.zen"),tDisabled,..Link("portal/socket_48.gif"),$$$Text("Join the existing mirror as failover member."))
	Set tDisabled = ..EvaluateCondition("'##class(SYS.MirrorConfiguration).EnableMirrorMenu(4)",.tError)
	Set tLinkTitle = $$$TextHTML("This option is enabled when this system is not already part of a mirror.")
	If tError '= "" Set tDisabled = 1,tLinkTitle = tError
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Join as Async"),tLinkTitle,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Mirror.JoinAsync.zen"),tDisabled,..Link("portal/socket_48.gif"),$$$Text("Join the existing mirror as Async member."))
	
	Set pData(n1,$i(n2)) = $LB($$$Text("Database Backup"),,,,..Link("portal/record_a_48.gif"))
	Set n3 = 0
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Database Backup List"),,..Link("/csp/sys/mgr/UtilSysBackupDatabases.csp?Recent=1"),,..Link("portal/gear_48.gif"),$$$Text("Define the backup database list that will be used by Full, Incremental and Cumulative backups."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Full Backup"),,..Link("/csp/sys/mgr/UtilSysBackup.csp?$ID1=FullAllDatabases&Recent=1"),,..Link("portal/iris_config_48.gif"),$$$Text("Configure Full backup of ALL databases, whether or not they are in the backup database list."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Backup of All on List"),,..Link("/csp/sys/mgr/UtilSysBackup.csp?$ID1=FullDBList&Recent=1"),,..Link("portal/bit_48.gif"),$$$Text("Configure Full backup of all databases that are in the backup database list."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Incremental Backup"),,..Link("/csp/sys/mgr/UtilSysBackup.csp?$ID1=IncrementalDBList&Recent=1"),,..Link("portal/bit_48.gif"),$$$Text("Configure Incremental backup of all databases that are in the backup database list."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Cumulative Backup"),,..Link("/csp/sys/mgr/UtilSysBackup.csp?$ID1=CumuIncrDBList&Recent=1"),,..Link("portal/bit_48.gif"),$$$Text("Configure Cumulative and Incremental backup of all databases that are in the backup database list."))
	#; This option requires %Admin_Secure
	Set pData(n1,$i(n2)) = $LB($$$Text("Web Gateway Management"),$S('tSecure:lblNoPriv,1:""),..Link("/csp/sys/mgr/UtilSysCSPGateway.csp?Recent=1"),$S(tSecure:0,1:1),..Link("portal/webstats_config_48.gif"),$$$Text("Manage Web Gateway systems."))

	Set pData(n1,$i(n2)) = $LB($$$Text("SQL and Object Settings"),,,,..Link("portal/sql_query_config_48.gif"))
	Set n3 = 0
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("SQL"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.SQL.Configure.SQL.zen"),,..Link("portal/sql_query_config_48.gif"),$$$Text("View or edit system-wide settings for SQL, DDL, and xDBC connectivity."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Objects"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ObjectSettings.zen"),,..Link("portal/objects_config_48.gif"),$$$Text("View or edit general object settings."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("TSQL Compatibility"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.SQL.Configure.TSQL.zen"),,..Link("portal/sql_query_config_48.gif"),$$$Text("View or edit the settings that define the behavior of InterSystems TSQL compatibility features."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("ISQL Compatibility"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.SQL.Configure.ISQL.zen"),,..Link("portal/sql_query_config_48.gif"),$$$Text("View or edit the settings that define the behavior of InterSystems ISQL compatibility features."))
	//Set pData(n1,n2,$i(n3)) = $LB($$$Text("FileMan Conversion Settings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.FileManConfigure.zen"),,..Link("portal/sql_query_config_48.gif"),$$$Text("View or edit the settings that define how FileMan data structures are converted to InterSystems class definitions."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("System DDL Mappings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.SQLDataTypes.zen?Subject=SystemDataTypes"),,..Link("portal/table_header_config_48.gif"),$$$Text("View or edit the table used to map standard DDL datatypes to InterSystems datatype classes."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("User DDL Mappings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.SQLDataTypes.zen?Subject=UserDataTypes"),,..Link("portal/table_header_config_48.gif"),$$$Text("View or edit the table used to map user-defined DDL datatypes to InterSystems datatype classes."))

	Set pData(n1,$i(n2)) = $LB($$$Text("Device Settings"),,,,..Link("portal/gear_48.gif"))
	Set n3 = 0
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Devices"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.Devices.zen"),,..Link("portal/iris_config_48.gif"),$$$Text("View or edit device definitions."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Magnetic Tape Devices"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.MagTapes.zen"),,..Link("portal/iris_config_48.gif"),$$$Text("View or edit magnetic tape device definitions."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Device Subtypes"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.SubTypes.zen"),,..Link("portal/iris_config_48.gif"),$$$Text("View or edit device subtype definitions."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("IO Settings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.IO.zen"),,..Link("portal/iris_config_48.gif"),$$$Text("View or edit input/output definitions."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Telnet Settings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.Telnet.zen"),,..Link("portal/iris_config_48.gif"),$$$Text("View or edit telnet definitions."))

	Set pData(n1,$i(n2)) = $LB($$$Text("Machine Learning Configurations"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ML.Configurations.zen"),,..Link("portal/flag_square_48.gif"),$$$Text("Define machine learning."))

	Set pData(n1,$i(n2)) = $LB($$$Text("National Language Settings"),,,,..Link("portal/flag_square_48.gif"),$$$Text("Configure national language support settings."))
	Set n3 = 0
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Configured Defaults"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.NLSConfigDefs.zen"),,..Link("portal/gateway_48.gif"),$$$Text("Display configured locale defaults."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Locale Definitions"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.NLS.zen"),,..Link("portal/gateway_48.gif"),$$$Text("Maintain NLS locale definitions."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Import Locales or Tables"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.NLSImport.zen"),,..Link("portal/insert_column_48.gif"),$$$Text("Import locale from a file."))
	
	Set pData(n1,$i(n2)) = $LB($$$Text("InterSystems Reports"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ReportServers.zen"),,..Link("portal/report_config_48.gif"),$$$Text("Configure server(s) for InterSystems Reports, powered by Logi Analytics" _ $CHAR(174) _ "."))
	Set pData(n1,$i(n2)) = $LB($$$Text("Zen Reports"),,,,..Link("portal/report_config_48.gif"))
	Set n3 = 0
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Render Servers"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ReportsRenderServers.zen"),,..Link("portal/report_config_48.gif"),$$$Text("Configure and manage HotJVM Report Render Servers."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Print Servers"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ReportsPrintServers.zen"),,..Link("portal/report_config_48.gif"),$$$Text("Configure and manage HotJVM Report Print Servers."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Excel Servers"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.ReportsExcelServers.zen"),,..Link("portal/report_config_48.gif"),$$$Text("Configure and manage HotJVM Report Excel Servers."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Settings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Reports.zen"),,..Link("portal/report_config_48.gif"),$$$Text("Configure Report settings."))

	Set pData(n1,$i(n2)) = $LB($$$Text("Additional Settings"),,,,..Link("portal/gear_48.gif"))
	Set n3 = 0
	#; This option requires %Admin_Secure
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Compatibility"),$S('tSecure:lblNoPriv,1:""),..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.Compatibility.zen"),$S(tSecure:0,1:1),..Link("portal/bit_48.gif"),$$$Text("Configure compatibility settings."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Advanced Memory"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.Memory.zen"),,..Link("portal/bit_48.gif"),$$$Text("Configure advanced memory settings."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Monitor"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Monitoring.zen"),,..Link("portal/network_monitor_config_48.gif"),$$$Text("Configure system monitoring settings."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Source Control"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.SourceControl.zen"),,..Link("portal/quality_48.gif"),$$$Text("Select Studio source control class."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Startup"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Config.Startup.zen"),,..Link("portal/calendar_48.gif"),$$$Text("Configure advanced startup settings."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Task Manager Email"),,..Link("/csp/sys/mgr/UtilSysTaskMail.csp?Recent=1"),,..Link("portal/mail_config_48.gif"),$$$Text("Configure task manager email settings."))

	// grouping of legacy settings	
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Legacy Settings"),,,,..Link("portal/gear_48.gif"))

	set n4 = 0
	Set pData(n1,n2,n3,$i(n4)) = $LB($$$Text("Shadow Server Settings"),,..Link("/csp/sys/mgr/%25CSP.UI.Portal.Shadows.zen"),,..Link("portal/socket_48.gif"),$$$Text("Shadowing is deprecated on IRIS. Configure current system as a shadow of selected databases on a primary system."))

	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit 0
}

/// This method is called only when user has %Admin_Secure priviledge
ClassMethod GetSecurityArray(n1, n2, Output pData) As %Status
{
	Set $ZT="Error"
	Set lblNoPriv = $$$TextHTML("You do not have privilege to view this page.","%Utility")
	Set tNoDBSecurity = '$System.Security.Check("%DB_IRISSYS","READ,WRITE")
	#; We put the first entry in main method so that the child is not null (even for disabled menu the ">>" can be shown)
 	Set pData(n1,$i(n2)) = $LB($$$Text("Roles"),tNoDBSecurity,..Link("/csp/sys/sec/%25CSP.UI.Portal.Roles.zen"),tNoDBSecurity,..Link("portal/role_48.gif"),$$$Text("View, add, or edit role definitions."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Resources"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Resources.zen"),tNoDBSecurity,..Link("portal/demographic_config_48.gif"),$$$Text("View, add, or edit resource definitions."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Services"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Services.zen"),tNoDBSecurity,..Link("portal/satellite_48.gif"),$$$Text("View or edit service definitions."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Applications"),,,tNoDBSecurity,..Link("portal/webstats_48.gif"),)
 	Set n3 = 0
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Web Applications"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Applications.WebList.zen"),tNoDBSecurity,..Link("portal/webstats_48.gif"),$$$Text("View, add, or edit Web application definitions."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Doc DB Applications"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Applications.DocDBList.zen"),tNoDBSecurity,..Link("portal/terminal_48.gif"),$$$Text("View, add, or edit Doc DB application definitions."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Privileged Routine Applications"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Applications.PrivRoutineList.zen"),tNoDBSecurity,..Link("portal/terminal_48.gif"),$$$Text("View, add, or edit privileged routine application definitions."))
 	i $$$ISWINDOWS {
 		Set pData(n1,n2,$i(n3)) = $LB($$$Text("Client Applications"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Applications.ClientList.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View, add, or edit client application definitions."))
 	}
	Set pData(n1,$i(n2)) = $LB($$$Text("Superservers"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Servers.zen"),tNoDBSecurity,..Link("portal/ssl_48.gif"),$$$Text("View, add, or edit Superserver configurations."))
	Set pData(n1,$i(n2)) = $LB($$$Text("SSL/TLS Configurations"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.SSLList.zen"),tNoDBSecurity,..Link("portal/ssl_48.gif"),$$$Text("View, add, or edit SSL/TLS configurations."))
	Set pData(n1,$i(n2)) = $LB($$$Text("X.509 Credentials"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.X509Credentials.zen"),tNoDBSecurity,..Link("portal/certificate_48.gif"),$$$Text("View, add, or edit X.509 credentials to be used with web services security."))

	If '$$$isVMS {  ; OAuth 2.0 not supported on VMS so no need for config screens in SMP
		Set pData(n1,$i(n2)) = $LB($$$Text("OAuth 2.0"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.OAuth2.Client.ConfigurationList.zen"),tNoDBSecurity,..Link("portal/ssl_48.gif"),$$$Text("View, add, or edit OAuth 2.0 Client Application Configurations."))
		Set n3 = 0
	 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Client"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.OAuth2.Client.ServerList.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View or edit OAuth 2.0 server descriptions on a client"))
	 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Server"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.OAuth2.Server.Configuration.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View or edit OAuth 2.0 server configuration"))
	 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Administration"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.OAuth2.Administration.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View or edit OAuth 2.0 administration options"))
	}
	
	Set pData(n1,$i(n2)) = $LB($$$Text("Managed File Transfer Connections"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.MFT.ConnectionList.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View, add, or edit Managed File Transfer Connections."))
	Set pData(n1,$i(n2)) = $LB($$$Text("System Security"),"View or edit values of general security settings.",,tNoDBSecurity,..Link("portal/security_config_48.gif"))
  	Set n3 = 0
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("System-wide Security Parameters"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Parameters.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View or edit system wide security parameters."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Authentication/Web Session Options"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Authentication.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View or edit authentication and Web Session options."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("LDAP/Kerberos Configurations"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.LDAPs.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("View or edit LDAP/Kerberos options."))
	Set tSecure = ..CheckSecurity("%Admin_Secure")
	If tSecure && 'tNoDBSecurity {
		Set tIsAuditingEnabled = ..EvaluateCondition("##class(Security.System).IsAuditingEnabled()",.tError)
	} Else {
		Set tIsAuditingEnabled = 0
		Set tError = ""
	}
	;Set tEMSecurity = ##class(%SYS.EMS).IsReadOnly("Security.System")
	Set tEMSecurity = 0
	Set tEnableDisabled = $S(tEMSecurity:1,tError="":tIsAuditingEnabled,1:1)
	Set tDisableDisabled = $S(tEMSecurity:1,tError="":'tIsAuditingEnabled,1:1)
	Set pData(n1,$i(n2)) = $LB($$$Text("Auditing"),,,tNoDBSecurity,..Link("portal/guard_search_48.gif"),$$$Text("Maintain audit events and view audit database."))
  	Set n3 = 0
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Enable Auditing"),tError,..Link("/csp/sys/sec/UtilSecAction.csp?Action=Enable"),(tEnableDisabled)||('tSecure)||(tNoDBSecurity),..Link("portal/form_48.gif"),$$$Text("Click to enable system auditing. This option is available only if system auditing is currently disabled."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Disable Auditing"),tError,..Link("/csp/sys/sec/UtilSecAction.csp?Action=Disable"),(tDisableDisabled)||('tSecure)||(tNoDBSecurity),..Link("portal/form_48.gif"),$$$Text("Click to disable system auditing. This option is available only if system auditing is currently enabled."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("View Audit Database"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Audit.View.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("Search and view system audit database records."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Configure System Events"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Audit.SystemEvents.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("Change enabled status for non-mandatory events, or reset any event counters."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Configure User Events"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Audit.UserEvents.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("Create, edit, export, import, reset, or delete user defined audit events."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Copy Audit Log"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Audit.CopyLog.zen"),,..Link("portal/form_48.gif"),$$$Text("Copy all items or items that are older than a number of days to a different namespace."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Export Audit Log"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Audit.ExportLog.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("Export all items or items that are older than a number of days to a file."))
 	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Purge Audit Log"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.Audit.PurgeLog.zen"),tNoDBSecurity,..Link("portal/form_48.gif"),$$$Text("Purge all items or items that are older than a number of days."))

	Set pData(n1,$i(n2)) = $LB($$$Text("Security Advisor"),,..Link("/csp/sys/sec/UtilSysSecurityAdvisor.csp?Recent=1"),('tSecure)||(tNoDBSecurity),..Link("portal/spyware_48.gif"),$$$Text("Invoke the Security Advisor."))
	Set pData(n1,$i(n2)) = $LB($$$Text("Mobile Phone"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.PhoneProviders.zen"),tNoDBSecurity,..Link("portal/mobile_phone_48.gif"),$$$Text("View or edit mobile phone service provider definitions."))

	Set pData(n1,$i(n2)) = $LB($$$Text("Public Key Infrastructure"),,..Link("/csp/sys/sec/%25CSP.UI.Portal.PKI.zen"),tNoDBSecurity,..Link("portal/keys_level_48.gif"),$$$Text("Configure Public Key Infrastructure."))
	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit 0
}

/// Provide finder contents for the System Explorer pages.
ClassMethod GetSystemExplorerArray(Output pData) As %Status
{
	Set tNotDev = '..CheckSecurity("%Development")
	If tNotDev = 1 Quit 1
	Set tNoDBSecurity = '$System.Security.Check("%DB_IRISSYS","READ,WRITE")
	Set tDisabled = 0
	Set lblNoPriv = ""
	If tNoDBSecurity,(($namespace = "%SYS")||($E($namespace,1,2)="^^")) Set tDisabled = 1, lblNoPriv = $$$Text("You do not have privilege to view this page in the current namespace. Please click 'Switch' to choose a new namespace.","%Utility") 

	//Set pMetaData = $LB("name","title","link","disabled","icon","description")
	Set pData($i(n1)) = $LB($$$Text("Classes"),$S(tDisabled:lblNoPriv,1:$$$Text("Browse class definitions on this system.")),..Link("/csp/sys/exp/%25CSP.UI.Portal.ClassList.zen"),tDisabled,..Link("portal/organigram_search_48.gif"),$$$Text("Browse classes in this namespace."))

	Set pData($i(n1)) = $LB($$$Text("SQL"),$S(tDisabled:lblNoPriv,1:$$$Text("Manage data on this system from a relational point of view.")),..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen"),tDisabled,..Link("portal/sql_query_48.gif"),$$$Text("Manage data on this system from a relational point of view."))
	Set pData($i(n1)) = $LB($$$Text("Routines"),$S(tDisabled:lblNoPriv,1:$$$Text("Browse routines on this system.")),..Link("/csp/sys/exp/%25CSP.UI.Portal.RoutineList.zen"),tDisabled,..Link("portal/script_48.gif"),$$$Text("Browse routines in this namespace."))
	Set pData($i(n1)) = $LB($$$Text("Globals"),$S(tDisabled:lblNoPriv,1:$$$Text("Browse globals on this system.")),..Link("/csp/sys/exp/%25CSP.UI.Portal.GlobalList.zen"),tDisabled,..Link("portal/atom_48.gif"),$$$Text("Browse globals in this namespace."))
	Set pData($i(n1)) = $LB($$$Text("Tools"),$S(tDisabled:lblNoPriv,1:$$$Text("Browse tools on this system.")),,tDisabled,..Link("portal/atom_48.gif"),$$$Text("Browse tools on this system."))
	Set n2 = 0
	Set pData(n1,$i(n2)) = $LB($$$Text("WebStress Tool"),,..Link("%25WebStress.Portal.Home.zen"),,..Link("portal/web_development_48.gif"),$$$Text("View WebStress Portal."))
	Set pData(n1,$i(n2)) = $LB($$$Text("UnitTest Portal"),,..Link("%25UnitTest.Portal.Home.zen"),,..Link("portal/web_development_48.gif"),$$$Text("View UnitTest Portal."))
	Set pData(n1,$i(n2)) = $LB($$$Text("SQL Performance Tools"),$S(tDisabled:lblNoPriv,1:$$$Text("Browse SQL performance tools")),,tDisabled,,)
	Set n3 = 0
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("SQL Runtime Statistics"),,..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.RuntimeStats.zen"),,..Link("portal/sql_query_config_48.gif"),$$$Text("Perform SQL runtime statistic diagnostics."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Index Analyzer"),,..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.IndexAnalyzer.zen"),,..Link("portal/table_48.gif"),$$$Text("View SQL index analyzer reports."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Alternate Show Plans"),,..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.ShowPlanAlt.zen"),,..Link("portal/table_48.gif"),$$$Text("View Alternate Show Plans."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Generate Report"),,..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.ReportGenerator.zen"),,..Link("portal/report_config_48.gif"),$$$Text("Generate SQL troubleshooting report."))
	Set pData(n1,n2,$i(n3)) = $LB($$$Text("Import Report"),,..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.ReportLoader.zen"),,..Link("portal/report_48.gif"),$$$Text("Import SQL troubleshooting report."))

	Quit $$$OK
}

ClassMethod GetNLPArray(ByRef n, ByRef pData) As %Status
{
	#; iKNOW options
	Set n1 = $I(n) // menu root index
	Set n2 = 0 // submenu index
	Set tProductName = $$$PRODUCT5
	// Check if menu should be disabled and provide helpful tooltip	
	Set tHoverTitle = $select('##class(%iKnow.UI.Dialog.selectNamespace).%IsiKnowEnabled($namespace):$$$FormatText($$$Text("Current namespace does not support %1. Please click 'Switch' to choose a new namespace."),tProductName),
	                        1:"")
	Set tDisabled = $select(tHoverTitle="":0,1:1) // if tooltip isn't defined, then menu is not disabled
	Set pData(n1) = $LB(tProductName,tHoverTitle,,tDisabled,) // disable menu
	
	// HSU038
	if 'tDisabled {
		// domain settings 
		Set pData(n1,$i(n2)) = $LB($$$Text("Domain Architect"),,..Link("_iKnow.UI.Architect.zen"),tDisabled,..Link("portal/eye_chart_48.gif"),$$$Text("Create and populate NLP domains and perform analysis on the indexed data."))
		Set pData(n1,$i(n2)) = $LB($$$Text("Domain Explorer"),,..Link("_iKnow.UI.KnowledgePortal.zen"),tDisabled,..Link("portal/eye_chart_48.gif"),$$$Text("Explore a wealth of information about source text data indexed in a domain."))
		Set pData(n1,$i(n2)) = $LB($$$Text("Indexing Results"),,..Link("_iKnow.UI.IndexingResults.zen"),tDisabled,..Link("portal/eye_chart_48.gif"),$$$Text("View the NLP indexing of the contents of an individual data source."))
	
		// text categorization
		set pData(n1,$i(n2)) = $lb($$$Text("Text Categorization"),,,tDisabled,)
		set n3 = 0
		set pData(n1,n2,$i(n3)) = $lb($$$Text("Model Builder"),,..Link("_iKnow.Classification.UI.ClassifierBuilder.zen"),tDisabled,..Link("portal/osi_model_48.gif"),$$$FormatText($$$Text("Build Text Categorization models based on an %1 domain."),tProductName))
		set pData(n1,n2,$i(n3)) = $lb($$$Text("Model Tester"),,..Link("_iKnow.Classification.UI.ClassifierTester.zen"),tDisabled,..Link("portal/osi_model_48.gif"),$$$FormatText($$$Text("Test Text Categorization models against a SQL query or %1 domain."),tProductName))
	}
	Quit $$$OK
}

/// Provide finder contents for the System Operator pages.
ClassMethod GetSystemOperationArray(Output pData) As %Status
{

	Set tOperate = '..CheckSecurity("%Admin_Operate")
	If tOperate = 1 Quit 1
	Set lblNoPriv = $$$TextHTML("You do not have privilege to view this page.","%Utility")
	Set tNoDBSecurity = '$System.Security.Check("%DB_IRISSYS","READ,WRITE")
	Set tNoDBSecurityRead = '$System.Security.Check("%DB_IRISSYS","READ")
	Set tHoverTitle = $S(tNoDBSecurity:lblNoPriv,1:"")
	Set tNoDBSecurityReadTitle = $S(tNoDBSecurityRead:lblNoPriv,1:"")
	//Set pMetaData = $LB("name","title","link","disabled","icon","description")
	Set pData($i(n1)) = $LB($$$Text("System Dashboard"),tNoDBSecurityReadTitle,..Link("/csp/sys/op/UtilDashboard.csp?Recent=1"),tNoDBSecurityRead,..Link("portal/network_monitor_48.gif"),$$$Text("View system real-time performance dashboard."))

	Set pData($i(n1)) = $LB($$$Text("Backup"),tHoverTitle,,tNoDBSecurity,..Link("portal/record_a_48.gif"))
 	Set n2 = 0
 	Set pData(n1,$i(n2)) = $LB($$$Text("Full Backup All Databases"),tHoverTitle,..Link("/csp/sys/op/UtilSysBackup.csp?$ID1=FullAllDatabases&Recent=1"),tNoDBSecurity,..Link("portal/user_id_48.gif"),$$$Text("Run full backup of ALL databases, whether or not they are in the backup database list."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Full Backup List"),tHoverTitle,..Link("/csp/sys/op/UtilSysBackup.csp?$ID1=FullDBList&Recent=1"),tNoDBSecurity,..Link("portal/role_48.gif"),$$$Text("Run full backup of all databases that are in the backup database list."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Incremental Backup List"),tHoverTitle,..Link("/csp/sys/op/UtilSysBackup.csp?$ID1=IncrementalDBList&Recent=1"),tNoDBSecurity,..Link("portal/gear_48.gif"),$$$Text("Run incremental backup of all databases that are in the backup database list."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Cumulative Backup List"),tHoverTitle,..Link("/csp/sys/op/UtilSysBackup.csp?$ID1=CumuIncrDBList&Recent=1"),tNoDBSecurity,..Link("portal/gear_48.gif"),$$$Text("Run cumulative and incremental backup of all databases that are in the backup database list."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Backup Status"),tHoverTitle,..Link("/csp/sys/op/UtilSysBackups.csp?Recent=1"),tNoDBSecurity,..Link("portal/gear_48.gif"),$$$Text("View current backup status log."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Backup History"),tHoverTitle,..Link("/csp/sys/op/UtilSysBackupLogs.csp?Recent=1"),tNoDBSecurity,..Link("portal/gear_48.gif"),$$$Text("View and explore recent system backup logs."))
		
	Set pData($i(n1)) = $LB($$$Text("Databases"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.OpDatabases.zen"),tNoDBSecurity,..Link("portal/database_48.gif"),$$$Text("Perform database tasks and view free space."))
	Set pData($i(n1)) = $LB($$$Text("Processes"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.Processes.zen"),tNoDBSecurity,..Link("portal/list_48.gif"),$$$Text("View current system processes."))
	Set pData($i(n1)) = $LB($$$Text("SQL Activity"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.SQL.CurrentStatements.zen"),tNoDBSecurity,..Link("portal/list_48.gif"),$$$Text("View currently executing SQL statements."))
	
	Set pData($i(n1)) = $LB($$$Text("Locks"),tNoDBSecurityReadTitle,,tNoDBSecurityRead,..Link("portal/lock_48.gif"))
 	Set n2 = 0
 	Set pData(n1,$i(n2)) = $LB($$$Text("View Locks"),tNoDBSecurityReadTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.LocksView.zen"),tNoDBSecurityRead,..Link("portal/lock_48.gif"),$$$Text("View current system locks."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Manage Locks"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.Locks.zen"),tNoDBSecurity,..Link("portal/lock_48.gif"),$$$Text("Manage current system locks."))
	
	Set pData($i(n1)) = $LB($$$Text("Journals"),tHoverTitle,..Link("/csp/sys/op/UtilSysJournals.csp?Recent=1"),tNoDBSecurity,..Link("portal/list_48.gif"),$$$Text("View system journal information."))
	Set pData($i(n1)) = $LB($$$Text("Transactions"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.Transactions.zen"),tNoDBSecurity,..Link("portal/list_48.gif"),$$$Text("View long-running transactions."))
	Set pData($i(n1)) = $LB($$$Text("Shadow Servers"),tHoverTitle,,tNoDBSecurity)
 	Set n2 = 0
 	Set pData(n1,$i(n2)) = $LB($$$Text("System as Shadow Server"),tHoverTitle,..Link("/csp/sys/op/UtilSysShadow.csp?Recent=1"),tNoDBSecurity,..Link("portal/symmetric_network_48.gif"),$$$Text("Manage shadow servers."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("System as Data Source"),tHoverTitle,..Link("/csp/sys/op/UtilSysShadowDataSource.csp?Recent=1"),tNoDBSecurity,..Link("portal/symmetric_network_48.gif"),$$$Text("Manage data source server."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Error Log"),tHoverTitle,..Link("/csp/sys/op/UtilSysShadowDataSourceErrors.csp?Recent=1"),tNoDBSecurity,..Link("portal/symmetric_network_48.gif"),$$$Text("Displays errors for data source."))

	Set pData($i(n1)) = $LB($$$Text("Mirror Monitor"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.Mirror.Monitor.zen"),tNoDBSecurity,..Link("portal/symmetric_network_48.gif"),$$$TextHTML("Monitor system mirror status."))

	Set pData($i(n1)) = $LB($$$Text("Task Manager"),,,,..Link("portal/calendar_48.gif"))
	Set tDisabled = '..CheckSecurity("%Admin_Task")
 	Set n2 = 0
 	Set pData(n1,$i(n2)) = $LB($$$Text("New Task"),$S(tDisabled:lblNoPriv,1:""),..Link("/csp/sys/op/UtilSysTaskBuilder.csp?Recent=1"),tDisabled,..Link("portal/gear_48.gif"),$$$Text("Create a new task schedule."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("On-demand Task"),,..Link("/csp/sys/op/%25CSP.UI.Portal.TasksOnDemand.zen"),,..Link("portal/gear_48.gif"),$$$Text("View a list of on-demand tasks and execute them."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Upcoming Tasks"),,..Link("/csp/sys/op/%25CSP.UI.Portal.TasksUpcoming.zen"),,..Link("portal/gear_48.gif"),$$$Text("View a list of tasks scheduled to run within the next 24 hours."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Task Schedule"),,..Link("/csp/sys/op/%25CSP.UI.Portal.TaskSchedule.zen"),,..Link("portal/gear_48.gif"),$$$Text("View all task schedules."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Task History"),,..Link("/csp/sys/op/%25CSP.UI.Portal.TaskHistory.zen"),,..Link("portal/gear_48.gif"),$$$Text("View a log of task manager activities."))
 	Set pData(n1,$i(n2)) = $LB($$$Text("Import Tasks"),$S(tDisabled:lblNoPriv,1:""),..Link("/csp/sys/op/UtilSysTaskAction.csp?Type=Import&Recent=1"),tDisabled,..Link("portal/gear_48.gif"),$$$Text("Import tasks from a file."))
	try {
		d 
		. n $namespace s $namespace="%SYS" 
		. d ##Class(Security.System).Get(,.Properties)
		. i $zb(+Properties("AutheEnabled"),$$$AutheKB,1) {
		. Set pData($i(n1)) = $LB($$$Text("LDAP/Kerberos Configurations"),tNoDBSecurityReadTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.LDAPsRO.zen"),tNoDBSecurityRead,..Link("portal/gear_48.gif"),$$$Text("View LDAP/Kerberos configurations."))
		. } else {
		. Set pData($i(n1)) = $LB($$$Text("LDAP Configurations"),tNoDBSecurityReadTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.LDAPsRO.zen"),tNoDBSecurityRead,..Link("portal/gear_48.gif"),$$$Text("View LDAP configurations."))
		. }
	} catch {
		. Set pData($i(n1)) = $LB($$$Text("LDAP Configurations"),tNoDBSecurityReadTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.LDAPsRO.zen"),tNoDBSecurityRead,..Link("portal/gear_48.gif"),$$$Text("View LDAP configurations."))
	}		
	Set pData($i(n1)) = $LB($$$Text("System Logs"),tHoverTitle,,tNoDBSecurity,..Link("portal/log_48.gif"))
 	Set n2 = 0
	Set pData(n1,$i(n2)) = $LB($$$Text("Application Error Log"),tHoverTitle,..Link("/csp/sys/op/UtilSysAppErrorNamespaces.csp?Recent=1"),tNoDBSecurity,..Link("portal/log_search_48.gif"),$$$Text("View or delete application errors."))
	Set pData(n1,$i(n2)) = $LB($$$Text("Messages Log"),tHoverTitle,..Link("/csp/sys/op/UtilSysConsoleLog.csp?Recent=1"),tNoDBSecurity,..Link("portal/log_search_48.gif"),$$$Text("View contents of the system messages log."))
	Set pData(n1,$i(n2)) = $LB($$$Text("xDBC Error Log"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.xDBCErrorNamespaces.zen"),tNoDBSecurity,..Link("portal/log_search_48.gif"),$$$Text("View ODBC or JDBC error log for local namespaces."))
	Set pData(n1,$i(n2)) = $LB($$$Text("System Monitor Log"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.ViewLog.zen"),tNoDBSecurity,..Link("portal/log_search_48.gif"),$$$Text("View contents of the system monitor log."))
	Set pData(n1,$i(n2)) = $LB($$$Text("SQL Diagnostics Log"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.SQL.Logs.zen"),tNoDBSecurity,..Link("portal/log_search_48.gif"),$$$Text("View contents of the SQL Diagnostics log."))

	Set pData($i(n1)) = $LB($$$Text("System Usage"),tHoverTitle,..Link("/csp/sys/op/UtilSysMonitor.csp?Recent=1"),tNoDBSecurity,..Link("portal/keys_search_48.gif"),$$$Text("View system usage monitor."))

	Set pData($i(n1)) = $LB($$$Text("License Usage"),,..Link("/csp/sys/op/%25CSP.UI.Portal.LicenseUsage.zen"),,..Link("portal/log_search_48.gif"),$$$Text("Displays current license activity summary."))
	Set pData($i(n1)) = $LB($$$Text("Interoperability Usage"),,..Link("/csp/sys/op/%25CSP.UI.Portal.InteroperabilityUsage.zen"),tNoDBSecurityRead,..Link("portal/log_search_48.gif"),$$$Text("Displays current Interoperability activity summary."))

	Set pData($i(n1)) = $LB($$$Text("Web Sessions"),tHoverTitle,..Link("/csp/sys/op/%25CSP.UI.Portal.CSPSessions.zen"),tNoDBSecurity,..Link("portal/webstats_48.gif"),$$$Text("View the current Web sessions."))
	Set pData($i(n1)) = $LB($$$Text("Background Tasks"),tHoverTitle,..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen"),tNoDBSecurity,..Link("portal/keys_search_48.gif"),$$$Text("View the current background tasks."))
	Set pData($i(n1)) = $LB($$$Text("Diagnostic Reports"),$S(tDisabled:lblNoPriv,1:""),..Link("/csp/sys/op/UtilSysButtons.csp?Recent=1"),tDisabled,..Link("portal/report_config_48.gif"),$$$Text("Run a diagnostic report and send it to InterSystems."))

	Quit $$$OK
}

/// Given a security resource, this method returns 1 if user has privilege, and 0 if the user does not security privilege for using a particular function.
ClassMethod CheckSecurity(pResource As %String) As %Boolean
{
	Quit $System.Security.Check(pResource,"USE")
}

/// Evaluate a menu item condition; the condition must refer to values or functions that
/// are in scope (i.e., % variables).
ClassMethod EvaluateCondition(pCondition As %String, tError As %String) As %Boolean
{
	New %ret
	Set %ret = 1
	Set tError = ""
	Set $ZT = "Trap"
	If (pCondition '= "") {
		Set x = "Set %ret = +(" _ pCondition _ ")"
		X x
	}
Done
	Quit %ret
Trap
	Set $ZT = ""
	Set %ret = 0
	If $ZE [ "<PROTECT>" Set tError = $$$Text("You do not have appropriate security privilege to complete this function.","%Utility")
	Set $ZE = ""
	Goto Done
}

}
