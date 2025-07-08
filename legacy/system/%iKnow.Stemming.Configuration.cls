/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>This class encapsulates the configuration settings of a customized <class>%iKnow.Stemmer</class>
/// object, as identified by a configuration name. Use <method>GetStemmer</method> to retrieve a 
/// saved stemmer configuration.</p>
/// Look at the subclasses for actual stemmer-specific parameters.
Class %iKnow.Stemming.Configuration Extends %Persistent [ Abstract, Deprecated, System = 4 ]
{

/// Name of this stemmer configuration. Should be unique within the namespace
Property Name As %String(MAXLEN = 150) [ Required ];

Index NameIndex On Name [ Unique ];

Method %OnNew(pName As %String) As %Status
{
	set ..Name = pName
	quit $$$OK
}

/// Instantiates a stemmer object based on the stemmer configuration saved with <property>Name</property> = <var>pName</var>.
/// Alternatively, if <var>pName</var> is a colon-delimited list of which the first entry is a valid
/// class name referring to a class that inherits from <class>%iKnow.Stemmer</class>, that class is
/// instantiated, using the remaining elements of the list as arguments for its %New method. 
ClassMethod GetStemmer(pName As %String, Output pStemmer As %iKnow.Stemmer) As %Status [ Final ]
{
	set pStemmer="", tSC = $$$OK
	try {
		if (..NameIndexExists(pName)) {
			set tConfig = ..NameIndexOpen(pName)
			set tSC = tConfig.CreateStemmerObject(.pStemmer)
			quit
		}
	
		// BDB587 - check if this is a stemmer class name
		set tClassName = $piece(pName,":",1)
		if $$$defClassDefined(tClassName) && $classmethod(tClassName,"%IsA","%iKnow.Stemmer") {
			for i = 2:1:$l(pName,":") {
				set tArgs($i(tArgs)) = $piece(pName,":",i)
			}
			set tObjLastError = $g(%objlasterror,$$$OK)
			set %objlasterror = $$$OK
			set pStemmer = $classmethod(tClassName,"%New",tArgs...)
			set tSC = $g(%objlasterror,$$$OK)
			set:'$$$ISERR(tSC) %objlasterror = tObjLastError
			quit:$$$ISERR(tSC)
		}
		
		set:'$isobject(pStemmer) tSC = $$$ERROR($$$GeneralError, "Stemming configuration '"_pName_"' not found")
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Instantiates a stemmer object based on the current object's configuration.
/// (Does not need to be persisted)
Method CreateStemmerObject(Output pStemmer As %iKnow.Stemmer) As %Status [ Abstract ]
{
}

ClassMethod NameIsValid(pValue As %String) As %Status [ Private, ServerOnly = 1 ]
{
	quit:pValue=$$$DEFAULTCONFIG $$$ERROR($$$GeneralError, "'"_$$$DEFAULTCONFIG_"' is a reserved name")
	quit:(pValue=1)||(pValue=0) $$$ERROR($$$GeneralError, "Invalid configuration name")
	quit $$$OK
}

Storage Default
{
<Data name="StemmerConfigDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^IRIS.IK.Sys.StemmerConfigD</DataLocation>
<DefaultData>StemmerConfigDefaultData</DefaultData>
<IdLocation>^IRIS.IK.Sys.StemmerConfigD</IdLocation>
<IndexLocation>^IRIS.IK.Sys.StemmerConfigI</IndexLocation>
<StreamLocation>^IRIS.IK.Sys.StemmerConfigS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
