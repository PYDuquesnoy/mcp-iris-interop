/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// ML Configuration Definitions for PMML provider
/// %SYS.ML.Configuration.Type=4 for PMML
/// 
Class %SYS.ML.PMML.Configuration Extends %SYS.ML.Configuration
{

/// Create PMML configuration
ClassMethod %Create(name As %String(MAXLEN=256), desc As %String(MAXLEN=256) = "", using As %String(MAXLEN="") = "", owner As %String(MAXLEN=160) = "") As %Status
{
	#dim sc As %Status
	#dim ex As %Exception.General
	#dim conf As %SYS.ML.PMML.Configuration
	#dim tmpJSON As %Library.DynamicObject
	set sc=$$$OK
	try {
		RETURN:$g(name)="" $$$ERROR($$$MLMissingParameter,"name","%Create")
		set conf=..%New()
		set conf.Name=name
		set conf.Type=3
		if using'="" {
			set tmpJSON={}.%FromJSON(using)	// make sure using is valid JSON string
			set conf.Using=tmpJSON.%ToJSON()
		}
		set:owner="" owner=$Username
		set conf.Owner=owner
		set conf.Description=desc
		set sc=conf.%Save()
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

Storage Default
{
<Data name="PMMLDefaultData">
<Subscript>"PMML"</Subscript>
</Data>
<DefaultData>PMMLDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
