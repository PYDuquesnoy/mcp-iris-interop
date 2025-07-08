/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// Model representation of the <class>%iKnow.Configuration</class> object.
/// See its class documentation for more details on specific properties.
Class %iKnow.Model.configuration Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

/// This relationship actually doesn't make sense as configurations are domain-independent,
/// but we need it for the object to compile.
Relationship domain As %iKnow.Model.domain(XMLPROJECTION = "none") [ Cardinality = one, Internal, Inverse = configurations ];

/// Name of the configuration. Must be unique within the namespace (across domains)
Property name As %String(MAXLEN = 150, XMLPROJECTION = "attribute");

/// Whether or not to let the iKnow engine automatically detect which of the languages listed in
/// <property>languages</property> each sentence is in.
Property detectLanguage As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// The language models to load in the engine when processing text. If the engine is to decide
/// which language each sentence / source is in, also set <property>detectLanguage</property> to 1
Property languages As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// If defined, uses this user dictionary to rewrite text fed into the engine.
Property userDictionary As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Whether or not to produce summary information while indexing text.
Property summarize As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// The maximum number of words in a concept. Concepts with more words will be interpreted as
/// noise and split into single-word concepts. Use this property to override the language model
/// default. Advanced use only!
Property maxConceptLength As %Integer(XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..name = "") {
			set tSC = $$$ERROR($$$GeneralError, "Configuration name is a required parameter")
			quit
		} else {
			set tConfig = ##class(%iKnow.Configuration).NameIndexOpen(..name)
			if $isobject(tConfig) {
				set tDefClass = ^IRIS.IK.Sys.Params(pDomainId,$$$IKPDEFINITIONCLASS)
				if '$d(^IRIS.IK.Sys.Definition(tDefClass,"config",tConfig.Id)) {
					set tSC = $$$ERROR($$$IKConfigurationExists, ..name)
					quit
				}
			}
		}
		
		if (..languages = "") {
			set tSC = $$$ERROR($$$GeneralError, "A configuration must specify at least one language")
			quit
		} else {
			for i = 1:1:$l(..languages,",") {
				set tLang = $$$LOWER($zstrip($piece(..languages,",",i),"<>W"))
				if '$lf($$$IKLANGUAGES,tLang) {
					set tSC = $$$ERROR($$$IKLanguageDoesNotExist, tLang)
					quit
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
