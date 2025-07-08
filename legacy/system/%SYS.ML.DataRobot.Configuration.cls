/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// ML Configuration Definitions for DataRobot provider
/// %SYS.ML.Configuration.Type=2 for DataRobot
/// 
Class %SYS.ML.DataRobot.Configuration Extends %SYS.ML.Configuration
{

Property url As %String(MAXLEN = 128) [ InitialExpression = "https://app.datarobot.com/", Required ];

Property apiToken As %String(MAXLEN = 512) [ Required ];

/// Create DataRobot configuration
ClassMethod %Create(name As %String(MAXLEN=256) = "", desc As %String(MAXLEN=256) = "", using As %String(MAXLEN="") = "", owner As %String(MAXLEN=160) = "", url As %String(MAXLEN="") = "", apiToken As %String(MAXLEN=512) = "") As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim conf As %SYS.ML.DataRobot.Configuration
	#dim tmpJSON As %Library.DynamicObject

	set sc=$$$OK
	try {
		RETURN:$g(name)="" $$$ERROR($$$MLMissingParameter,"name","%Create")
		set conf=..%New()
		set:name'="" conf.Name=name			// filer will report an error if not defined
		set conf.Type=2
		set:url'="" conf.url=url			// filer will use initialexpression is not defined
		set:apiToken'="" conf.apiToken=apiToken		// filer will report an error if not defined
		if using'="" {
			set tmpJSON={}.%FromJSON(using)	// make sure using is valid JSON string
			set conf.Using=tmpJSON.%ToJSON()
		}
		set:owner="" owner=$Username
		set conf.Owner=owner
		set:desc'="" conf.Description=desc
		set sc=conf.%Save()
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

/// Modify an ML configuration
/// name     - Name of the configuration to modify
/// desc     - Description for the configuration
/// using    - default USING clause for the configuration.  This is a JSON string of ket:value pairs (See CREATE MODEL for examples)
/// owner    - Username/Rolename that owns this ML Configuration
/// url      - Uniform Resource Locator for this ML Configuration
/// apiToken - apiToken for this ML Configuration
///     To change Description, Using, Owner, url apiTokem, supply a new value (including "" to set the new value to null).  
///     To leave the value alone, don't pass any value for the parameter 
///     Name and Type cannot be modified
ClassMethod %Modify(name As %String(MAXLEN=256), desc As %String(MAXLEN=256), using As %String(MAXLEN=4096), owner As %String(MAXLEN=160), url As %String(MAXLEN=""), apiToken As %String(MAXLEN=512)) As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim conf As %SYS.ML.AutoML.Configuration
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
		set:$d(url)#2 config.url=url
		set:$d(apiToken)#2 config.apiToken=apiToken
		set sc=config.%Save()
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

Storage Default
{
<Data name="DataRobotDefaultData">
<Subscript>"DataRobot"</Subscript>
<Value name="1">
<Value>url</Value>
</Value>
<Value name="2">
<Value>apiToken</Value>
</Value>
</Data>
<DefaultData>DataRobotDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
