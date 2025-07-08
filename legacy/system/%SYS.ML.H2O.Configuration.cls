/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// ML Configuration Definitions for H2O provider
/// %SYS.ML.Configuration.Type=1 for H2O
/// 
Class %SYS.ML.H2O.Configuration Extends %SYS.ML.Configuration
{

Property javaTlsConfigFile As %String(MAXLEN = 4096);

/// Create H2O configuration
ClassMethod %Create(name As %String(MAXLEN=256), desc As %String(MAXLEN=256) = "", using As %String(MAXLEN="") = "", owner As %String(MAXLEN=160) = "", javaTlsConfigFile As %String(MAXLEN=4096) = "") As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim conf As %SYS.ML.H2O.Configuration
	#dim tmpJSON As %Library.DynamicObject
	set sc=$$$OK
	try {
		RETURN:$g(name)="" $$$ERROR($$$MLMissingParameter,"name","%Create")
		set conf=..%New()
		set conf.Name=name
		set conf.Type=1
		if using'="" {
			set tmpJSON={}.%FromJSON(using)	// make sure using is valid JSON string
			set conf.Using=tmpJSON.%ToJSON()
		}
		set:owner="" owner=$Username
		set conf.Owner=owner
		set conf.Description=desc
		set conf.javaTlsConfigFile=javaTlsConfigFile
		set sc=conf.%Save()
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Modify an ML configuration
/// name              - Name of the configuration to modify
/// desc              - Description for the configuration
/// using             - default USING clause for the configuration.  This is a JSON string of key:value pairs (See CREATE MODEL for examples)
/// owner             - Username/Rolename that owns this ML Configuration
/// javaTlsConfigFile - Path to Java client TLS configuration file to connect to superserver
///     To change Description, Using, Owner, or javaTlsConfigFile, supply a new value (including "" to set the new value to null).  
///     To leave the value alone, don't pass any value for the parameter 
///     Name and Type cannot be modified
ClassMethod %Modify(name As %String(MAXLEN=256), desc As %String(MAXLEN=256), using As %String(MAXLEN=4096), owner As %String(MAXLEN=160), javaTlsConfigFile As %String(MAXLEN=4096)) As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim config As %SYS.ML.H2O.Configuration
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
		set:$d(javaTlsConfigFile)#2 config.javaTlsConfigFile=javaTlsConfigFile
		set sc=config.%Save()
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

Storage Default
{
<Data name="H2ODefaultData">
<Subscript>"H2O"</Subscript>
<Value name="1">
<Value>javaTlsConfigFile</Value>
</Value>
</Data>
<DefaultData>H2ODefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
