/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Configuration settings for a stemmer supporting multiple languages. Each language can be
/// configured separately, or just use the default settings.
/// <p>Unless you're using custom configurations, using the default configuration ("DEFAULT") will
/// automatically support multiple languages. See also <class>%iKnow.Stemming.DefaultStemmer</class>.</p>
Class %iKnow.Stemming.MultiLanguageConfig Extends %iKnow.Stemming.Configuration [ Deprecated, System = 4 ]
{

/// Comma-separated list of languages this stemmer supports, or "*" if it supports all
Property Languages As %String;

/// Comma-separated list of custom configurations to use for each language in <property>Languages</property>.
/// Entries left blank will be instantiated using the default configuration.
Property StemmerConfigs As %String;

Method CreateStemmerObject(Output pStemmer As %iKnow.Stemmer) As %Status
{
	set tSC = $$$OK
	try {
		set tLanguages = $case(..Languages, "*":$lts($$$IKLANGUAGES), :..Languages)
		
		set pStemmer = ##class(%iKnow.Stemming.MultiLanguageStemmer).%New()
		set pStemmer.DefaultLanguage = $piece(tLanguages,",",1)
		
		set l = $l(tLanguages,",")
		for i = 1:1:l {
			set tLanguage = $piece(tLanguages,",",i), tConfig = $piece(..StemmerConfigs,",",i)
			
			if (tConfig="") {
				set tSC = ##class(%iKnow.Stemmer).GetDefault(tLanguage, .tStemmer)
				quit:$$$ISERR(tSC)
			} else {
				set tSC = ##class(%iKnow.Stemmer).GetCustom(tConfig, .tStemmer)
				quit:$$$ISERR(tSC)
			}
			set pStemmer.Stemmers(tLanguage) = tStemmer
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="MultiLanguageConfigDefaultData">
<Subscript>"MultiLanguageConfig"</Subscript>
<Value name="1">
<Value>Languages</Value>
</Value>
<Value name="2">
<Value>StemmerConfigs</Value>
</Value>
</Data>
<DefaultData>MultiLanguageConfigDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
