/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occErrors

/// 
/// ML Configuration Definitions.  This super class should be extended by different providers
/// to allow for custom configurations.  Any configuration settings common to all providers should be defined in this class.
/// 
Class %SYS.ML.Configuration Extends %Persistent [ SqlRowIdPrivate, System = 4 ]
{

Parameter SQLPUBLICSECURITY = "{""%GetDefault"":""E""}";

/// Configuration name
Property Name As %String(MAXLEN = 256) [ Required ];

/// Provider
/// 0 = AutoML, 1 = H2O, 2 = DataRobot, 3 = PMML
Property Type As %EnumString(DISPLAYLIST = ",AutoML,H2O,DataRobot,PMML", VALUELIST = ",0,1,2,3") [ InitialExpression = 0, Required ];

/// Description of this Configurtion
Property Description As %String(MAXLEN = 256);

/// Default USING clause for the provider
Property Using As %String(MAXLEN = 4096);

/// Username/Rolename that is the owner of this ML Configuration
/// The owner will always implicitly have USE privilege for the configuration
Property Owner As %String(MAXLEN = 160);

Index NameIndex On Name [ PrimaryKey, Unique ];

Trigger %NoSQLFiling [ Event = INSERT/UPDATE/DELETE, Foreach = row, Language = objectscript ]
{
	set %ok=0,%msg="SQL INSERT/UPDATE/DELETE is not allowed for ML Configurations"
}

/// Create default ML configuration
/// name - Name of the configuration, required, must be unique.  String with MAXLEN=256
/// desc - Optional description for the configuration
/// using - default USING clause for the configuration.  This is a JSON string of key:value pairs (See CREATE MODEL for examples)
ClassMethod %Create(name As %String(MAXLEN=256), desc As %String(MAXLEN=256) = "", using As %String(MAXLEN=4096) = "", owner As %String(MAXLEN=160) = "") As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim conf As %SYS.ML.AutoML.Configuration
	#dim tmpJSON As %Library.DynamicObject
	set sc=$$$OK
	try {
		RETURN:$g(name)="" $$$ERROR($$$MLMissingParameter,"name","%Create")
		set conf=..%New()
		set conf.Name=name
		set conf.Type=0
		if using'="" {
			set tmpJSON={}.%FromJSON(using)	// make sure using is valid JSON string
			set conf.Using=tmpJSON.%ToJSON()
		}
		set conf.Description=desc
		set:owner="" owner=$Username
		set conf.Owner=owner
		set sc=conf.%Save()
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Modify an ML configuration
/// name  - Name of the configuration to modify
/// desc  - Description for the configuration
/// using - default USING clause for the configuration.  This is a JSON string of key:value pairs (See CREATE MODEL for examples)
/// owner - Username/Rolename that owns this ML Configuration
///     To change Description, Using, or Owner, supply a new value (including "" to set the new value to null).  
///     To leave the value alone, don't pass any value for the parameter 
///     Name and Type cannot be modified
ClassMethod %Modify(name As %String(MAXLEN=256), desc As %String(MAXLEN=256), using As %String(MAXLEN=4096), owner As %String(MAXLEN=160)) As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim conf As %SYS.ML.Configuration
	#dim tmpJSON As %Library.DynamicObject
	set sc=$$$OK
	try {
		set config=..NameIndexOpen(name,,.sc)
		if $$$GETERRORCODE(sc)=$$$KeyValueNotFoundOpen { set sc=$$$ERROR($$$MLConfigurationNotFound,name) }
		quit:$$$ISERR(sc)
		if $d(using)#2 {
			if using'="" {
				set tmpJSON={}.%FromJSON(using)	// make sure using is valid JSON string
				set config.Using=tmpJSON.%ToJSON()
			} else { set config.Using="" }
		}
		set:$d(desc)#2 config.Description=desc
		set:$d(owner)#2 config.Owner=owner
		set sc=config.%Save()
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Modify an ML configuration from an SQL ALTER ML CONFIGURATION Statement
/// Internal method only, called from ALTER ML CONFIGURATION execution and from SMP %CSP.UI.Portal.ML.Configuration.SaveData()
/// name              - Name of the configuration to modify
/// desc              - Description for the configuration
/// using             - New using clause
/// javaTlsConfigFile - New Java TLS configuration file, H2O only
/// url               - New url value, DataRobot only
/// apiToken          - New apiToken value, DataRobot only
/// owner             - New owner name
/// %msg              - Byref, Error string returned to SQL
///     To change Provider, Description, Using, javaTlsConfigFile, Url, or apiToken, supply a new value (including "" to set the new value to null).  
///     To leave the value alone, don't pass any value for the parameter 
///     Name cannot be modified
/// RETURNS SQLCODE
ClassMethod %SQLAlter(name As %String(MAXLEN=256), provider As %String, desc As %String(MAXLEN=256), using As %String(MAXLEN=4096), javaTlsConfigFile As %String, ByRef url As %String, ByRef apiToken As %String, ByRef owner As %String, ByRef %msg As %String) As %Integer [ Final, Internal ]
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim confif As %SYS.ML.Configuration
	#dim tmpJSON As %Library.DynamicObject
	#dim SQLCODE,i As %Integer
	#dim errlist As %String
	
	set sc=$$$OK,SQLCODE=0
	try {
		&sql(select %ID, Type into :mlconfigid,:type from %SYS_ML.Configuration where Name = :name)
		if SQLCODE=100 { set %msg="ML Configuration '"_name_"' not found" RETURN -187 }
		if SQLCODE<0 { RETURN SQLCODE }
		set config=..%OpenId(mlconfigid,4,.sc)
		if $$$ISERR(sc) {
			do DecomposeStatus^%apiOBJ(sc,.errlist)
			set %msg="Error in %OpenId for ML Configuration '"_name_"', id '"_mlconfigid_"'  "
			for i=1:1:errlist { set %msg=%msg_errlist(i)_$s(i>1:"  ",1:"") }
			RETURN -400
		}
		if config=$$$NULLOREF { set %msg="ML Configuration '"_name_"' not found" RETURN -187 }
		if '$d(provider)||($$$LOWER($g(provider))=$case(config.Type,0:"automl",1:"h2o",2:"datarobot",3:"pmml",:0)) {	// Not changing the provider - easy
			if $d(using)#2 {
				if using'="" {
					set tmpJSON={}.%FromJSON(using)	// make sure using is valid JSON string
					set config.Using=tmpJSON.%ToJSON()
				} else { set config.Using="" }
			}
			set:$d(desc)#2 config.Description=desc
			set:$d(owner)#2 config.Owner=owner
			if config.Type=1 {  // H2O
				set:$d(javaTlsConfigFile)#2 config.javaTlsConfigFile=javaTlsConfigFile
			} elseif config.Type=2 {	// DataRobot
				set:$d(url)#2 config.url=url
				set:$d(apiToken)#2 config.apiToken=apiToken
			}
			if config.Type'=1,$d(javaTlsConfigFile)#2,javaTlsConfigFile'="" {
				set %msg="ML Configuration '"_name_"' does not support the 'javaTlsConfigFile' property"
				RETURN -188
			}
			if config.Type'=2,$d(apiToken)#2,apiToken'="" {
				set %msg="ML Configuration '"_name_"' does not support the 'apiToken' property"
				RETURN -188
			}
			if config.Type'=2,$d(url)#2,url'="" {
				set %msg="ML Configuration '"_name_"' does not support the 'url' property"
				RETURN -188
			}
			set sc=config.%Save()
			if $$$ISERR(sc) {
				do DecomposeStatus^%apiOBJ(sc,.errlist)
				set %msg="Error in %Save for ML Configuration '"_name_"'  "
				for i=1:1:errlist { set %msg=%msg_errlist(i)_$s(i>1:"  ",1:"") }
				RETURN -400
			}
			RETURN 0	// Success
		}
			#; we are modifying the provider - changing the type of the class, update globals directly
		set newprovider=$case($$$LOWER(provider),"automl":"AutoML","h2o":"H2O","datarobot":"DataRobot","pmml":"PMML",:"zzz")
		set oldprovider=$case(config.Type,0:"AutoML",1:"H2O",2:"DataRobot",3:"PMML",:"AutoML")
		if newprovider="zzz" { set %msg="Provider '"_provider_"' not found" RETURN -184 }
		set data=$g(^%SYS("ml","configuration","d",mlconfigid))
		if $d(using)#2 {
			if using'="" {
				set tmpJSON={}.%FromJSON(using)	// make sure using is valid JSON string
				set $li(data,4)=tmpJSON.%ToJSON()
			} else { set $li(data,4)="" }
		}
		set:$d(desc)#2 $li(data,5)=desc
		set:$d(owner)#2 $li(data,6)=owner
		
		if newprovider'="H2O",$d(javaTlsConfigFile)#2,javaTlsConfigFile'="" {
			set %msg="ML Configuration '"_name_"' does not support the 'javaTlsConfigFile' property"
			RETURN -188
		}
		if newprovider'="DataRobot",$d(apiToken)#2,apiToken'="" {
			set %msg="ML Configuration '"_name_"' does not support the 'apiToken' property"
			RETURN -188
		}
		if newprovider'="DataRobot",$d(url)#2,url'="" {
			set %msg="ML Configuration '"_name_"' does not support the 'url' property"
			RETURN -188
		}
		if newprovider="DataRobot" {
			if $g(url)="" { set %msg="ML Configuration '"_name_"' is missing the required 'url' property value" RETURN -108 }
			if $g(apiToken)="" { set %msg="ML Configuration '"_name_"' is missing the required 'apiToken' property value" RETURN -108 }
		}

		if newprovider="AutoML" {
			set $li(data,1)="~%SYS.ML.AutoML.Configuration~"
			set $li(data,3)=0 // Type
			set ^%SYS("ml","configuration","d",mlconfigid)=data
			set ^%SYS("ml","configuration","d",mlconfigid,newprovider)=""
			set ^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(name),mlconfigid)="~%SYS.ML.AutoML.Configuration~"
			kill ^%SYS("ml","configuration","d",mlconfigid,oldprovider)
		} elseif newprovider="H2O" {
			set $li(data,1)="~%SYS.ML.H2O.Configuration~"
			set $li(data,3)=1 // Type
			set ^%SYS("ml","configuration","d",mlconfigid)=data
			set ^%SYS("ml","configuration","d",mlconfigid,newprovider)=$lb(javaTlsConfigFile)
			set ^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(name),mlconfigid)="~%SYS.ML.H2O.Configuration~"
			kill ^%SYS("ml","configuration","d",mlconfigid,oldprovider)
		} elseif newprovider="DataRobot" {
			set $li(data,1)="~%SYS.ML.DataRobot.Configuration~"
			set $li(data,3)=2 // Type
			set ^%SYS("ml","configuration","d",mlconfigid)=data
			set ^%SYS("ml","configuration","d",mlconfigid,newprovider)=$lb(url,apiToken)
			set ^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(name),mlconfigid)="~%SYS.ML.DataRobot.Configuration~"
			kill ^%SYS("ml","configuration","d",mlconfigid,oldprovider)
		} elseif newprovider="PMML" {
			set $li(data,1)="~%SYS.ML.PMML.Configuration~"
			set $li(data,3)=3 // Type
			set ^%SYS("ml","configuration","d",mlconfigid)=data
			set ^%SYS("ml","configuration","d",mlconfigid,newprovider)=""
			set ^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(name),mlconfigid)="~%SYS.ML.PMML.Configuration~"
			kill ^%SYS("ml","configuration","d",mlconfigid,oldprovider)
		}

	} catch (ex) {
		set sc = ex.AsStatus()
		set SQLCODE=-400
		do DecomposeStatus^%apiOBJ(sc,.errlist)
		set %msg="Error in execution of ALTER ML CONFIGURATION '"_name_"'  "
		for i=1:1:errlist { set %msg=%msg_errlist(i)_$s(i>1:"  ",1:"") }
	}
		#; When we return, the config oref is destructed and we unlock the ML Configuration
	RETURN SQLCODE
}

/// Remove configuration
ClassMethod %Remove(name As %String(MAXLEN=256), tempDrop As %Boolean = 0) As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	set sc=$$$OK
	try {
			#; CREATE OR REPLACE ML CONFIGURATION will allow "dropping" the system default config
			#; DROP ML CONFIGURATION will throw $$$MLCannotDeleteDefaultConfig
		if 'tempDrop, $$$LOWER(..%GetSystemDefault())=$$$LOWER(name) { set sc=$$$ERROR($$$MLCannotDeleteDefaultConfig,name) quit }
		&sql(select %id into :id from %SYS_ML.Configuration where Name = :name)
		if SQLCODE<0 { set sc=$$$ERROR($$$SQLError,SQLCODE,%msg) }
		elseif SQLCODE=100 { set sc=$$$ERROR($$$MLConfigurationNotFound,name) quit }
		set sc=##class(%SYS.ML.Configuration).%DeleteId(id)
		if 'tempDrop, $$$ISOK(sc) {
				#;   Delete all the Configuration's privileges, need to revoke privileges on configuration from everyone
			do setup1^%SYS.SQLSEC("l",6,$lb(name),"*",0,1,1,,"*",,1)
		}
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Create default configurations for all providers
ClassMethod %CreateDefaults() As %Status [ Final, Internal ]
{
	#dim sc As %Status
	#dim ex As %Exception.General
	
	set sc=$$$OK
	try {
		if '..NameIndexExists("%AutoML") {
			set sc=##class(%SYS.ML.AutoML.Configuration).%Create("%AutoML","Default AutoML Configuration","","_SYSTEM")
			RETURN:$$$ISERR(sc) sc
		}
		if '..NameIndexExists("%H2O") {
			set sc=##class(%SYS.ML.H2O.Configuration).%Create("%H2O","Default H2O Configuration","","_SYSTEM")
			RETURN:$$$ISERR(sc) sc
		}
#;		if '..NameIndexExists("%DataRobot") {
#;			set sc=##class(%SYS.ML.DataRobot.Configuration).%Create("%DataRobot","Default DataRobot Configuration","","_SYSTEM","https://app.datarobot.com/")
#;			RETURN:$$$ISERR(sc) sc
#;		}
		if '..NameIndexExists("%PMML") {
			set sc=##class(%SYS.ML.PMML.Configuration).%Create("%PMML","Default PMML Configuration","","_SYSTEM")
			RETURN:$$$ISERR(sc) sc
		}
		if $g(^%SYS("ml","configuration","default"))="" { 
			set sc=..%SetSystemDefault("%AutoML")
		}
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Sets the system-wide default ML Configuration
ClassMethod %SetSystemDefault(name As %String(MAXLEN=256)) As %Status [ Final ]
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim config As %SYS.ML.Configuration
	
	set sc=$$$OK
	try {
		set config=..NameIndexOpen(name,,.sc)
		if $$$ISOK(sc) {
			set ^%SYS("ml","configuration","default")=config.Name
			RETURN $$$OK
		}
		if $$$GETERRORCODE(sc)=$$$KeyValueNotFoundOpen { set sc=$$$ERROR($$$MLConfigurationNotFound,name) }
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Returns the system-wide default ML Configuration
///  if no system wide default is defined (which really should not happen), "" is returned
ClassMethod %GetSystemDefault() As %String(MAXLEN=256) [ Final ]
{
	#dim ex As %Exception.General
	
	try {
		RETURN $g(^%SYS("ml","configuration","default"),"%AutoML")
	} catch (ex) {
	}
	RETURN ""
}

/// Sets the current process's default ML Configuration
ClassMethod %SetDefault(name As %String(MAXLEN=256)) As %Status [ Final ]
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim id As %SYS.ML.Configuration
	
	set sc=$$$OK
	try {
		set config=..NameIndexOpen(name,,.sc)
		if $$$ISOK(sc) {
			set $system.Context.SQL().MLConfiguration=config.Name
			RETURN $$$OK
		}
		if $$$GETERRORCODE(sc)=$$$KeyValueNotFoundOpen { set sc=$$$ERROR($$$MLConfigurationNotFound,name) }
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Returns the current process's default ML Configuration
/// Returns "" if an error or the ML Configuration no longer exists and there is no system default
ClassMethod %GetDefault() As %String(MAXLEN=256) [ Final, SqlName = %GetDefault, SqlProc ]
{
	#dim config As %String = ""
	#dim sc As %Status
	try {
		set config=$system.Context.SQL().MLConfiguration
		if '$data(^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(config))) {  // process's default ML Config no longer exists
			set config=..%GetSystemDefault()	// Get the system default
			if config'="" {				// If there is a system default
				set sc=..%SetDefault(config)	// update the process default to be the system default
				if $$$ISERR(sc) { set config="" }
			}
		}
	} catch {
		set config=""
	}
	RETURN config
}

/// Sets the current process's default ML Configuration, called from SET ML CONFIGURATION <name>
ClassMethod %SetDefaultSQL(name As %String(MAXLEN=256), ByRef SQLCODE As %Integer, ByRef %msg As %String = "") [ Final, Internal ]
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim id As %SYS.ML.Configuration
	#dim i as %Integer
	#dim errlist As %String
	
	set sc=$$$OK,SQLCODE=0,%msg="",%ROWCOUNT=0
	try {
		set SQLCODE=0,%msg=""
		set config=..NameIndexOpen(name,,.sc)
		if $$$ISOK(sc) {
			set $system.Context.SQL().MLConfiguration=config.Name
			RETURN $$$OK
		}
		if $$$GETERRORCODE(sc)=$$$KeyValueNotFoundOpen { set SQLCODE=-187,%msg="ML Configuration name '"_name_"' was not found" }
		else {
			set SQLCODE=-400
			do DecomposeStatus^%apiOBJ(sc,.errlist)
			for i=1:1:errlist { set %msg=errlist(i)_$s(i>1:"  ",1:"") }
		}
	} catch (ex) {
		set SQLCODE=-400,%msg="Unexpected error in SET ML CONFIGURATION "_name_".  $ZError = "_$ze
	}
	RETURN
}

/// Given an ML Configuration name, get the owner of the configuration
/// If ML Configuration does not exist or any other error, return ""
/// Called from %SYS.SQLSEC
ClassMethod %GetOwner(name As %String(MAXLEN=256)) As %String(MAXLEN=160) [ Final, Internal ]
{
	#dim config As %SYS.ML.Configuration
	#dim ex As %Exception.General
	#dim sc As %Status
	try {
		set config=..NameIndexOpen(name,,.sc)
		RETURN:$$$ISERR(sc) ""
		RETURN config.Owner
	} catch (ex) {
	}
	RETURN ""
}

/// Given the name of a ML Configuration, return the name of the provider
ClassMethod %GetProviderFromName(name As %String(MAXLEN=256), ByRef sc As %Status) As %String(MAXLEN=256) [ Final ]
{
	new %msg,%ROWCOUNT,%ROWID
	try {
		#sqlcompile select=display
		set sc=$$$OK
		&sql(select Type into :type from %SYS_ML.Configuration where Name = :name)
		if 'SQLCODE { RETURN $s(type="DataRobot":"DR",1:type) }	// ML Configuration type "DataRobot" referes to Provider "DR"
		if SQLCODE<0 { set sc=$$$ERROR($$$SQLError,SQLCODE,%msg) }
		else { set sc=$$$ERROR($$$MLConfigurationNotFound,name) }
	} catch ex {
		set sc=ex.AsStatus()
	}
	RETURN "AutoML"
}

/// Given the name of a ML Configuration, return the using property value
/// "" returned upon error
ClassMethod %GetUsingFromName(name As %String(MAXLEN=256)) As %Library.DynamicObject [ Final ]
{
	#dim config As %SYS.ML.Configuration
	
	try {
		set config=..NameIndexOpen(name,,.sc)
		RETURN:$$$ISERR(sc) ""
		RETURN:config.Using="" ""
		RETURN ##class(%DynamicObject).%FromJSON(config.Using)
	} catch {
	}
	RETURN ""
}

/// Return a $list of all ML Configuration names
/// Called from %SYS.SQLSEC for granting USE Privilege to all ML Configurations
/// If there is an error, SQLCODE and %msg implicitly returned
ClassMethod %GetListOfAllConfigNames(ByRef SQLCODE As %Integer, ByRef %msg As %String) As %Library.List [ Final, Internal, PublicList = (SQLCODE, names) ]
{
	try {
		new names,%ROWCOUNT
		&sql(select %dlist(Name) into :names from %SYS_ML.Configuration)
		RETURN:SQLCODE ""
		RETURN names
	} catch {
	}
	RETURN ""
}

Storage Default
{
<Data name="ConfigurationDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
<Value name="4">
<Value>Using</Value>
</Value>
<Value name="5">
<Value>Description</Value>
</Value>
<Value name="6">
<Value>Owner</Value>
</Value>
</Data>
<DataLocation>^%SYS("ml","configuration","d")</DataLocation>
<DefaultData>ConfigurationDefaultData</DefaultData>
<IdLocation>^%SYS("ml","configuration","d")</IdLocation>
<IndexLocation>^%SYS("ml","configuration","i")</IndexLocation>
<StreamLocation>^%SYS("ml","configuration","s")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
